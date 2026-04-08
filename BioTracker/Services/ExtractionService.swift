import Foundation

enum ExtractionError: LocalizedError {
    case missingAPIKey
    case imageEncodingFailed
    case apiError(String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "No Anthropic API key set. Add one in Settings."
        case .imageEncodingFailed: "Could not encode image."
        case .apiError(let m): "API error: \(m)"
        case .parseError(let m): "Could not parse extraction: \(m)"
        }
    }
}

/// Calls Anthropic's vision API to extract structured lab results from a photo.
/// Returns JSON Data shaped as `LabResultsImport`, ready to feed into `ImportService.importData`.
struct ExtractionService {
    static let apiKeyDefaultsKey = "anthropic_api_key"

    static var apiKey: String? {
        let key = UserDefaults.standard.string(forKey: apiKeyDefaultsKey)
        return (key?.isEmpty ?? true) ? nil : key
    }

    static func extract(imageData: Data) async throws -> Data {
        guard let key = apiKey else { throw ExtractionError.missingAPIKey }

        let base64 = imageData.base64EncodedString()

        let prompt = """
        You are extracting structured data from a photo of a blood lab result.
        Return ONLY a single JSON object — no prose, no markdown fences — matching this exact schema:

        {
          "type": "lab_results",
          "version": "1.0",
          "bloodDraw": {
            "collectionDate": "YYYY-MM-DD",
            "labSource": "<lab name as printed, or 'Unknown'>",
            "fasting": null,
            "sourceFileName": null,
            "notes": null
          },
          "readings": [
            {
              "biomarkerName": "<canonical name, e.g. 'Total Cholesterol'>",
              "category": "<one of: Lipids, Glucose, Liver, Kidney, Thyroid, Hormones, Vitamins, CBC, Inflammation, Other>",
              "value": <number or null>,
              "unit": "<unit string>",
              "flag": "<one of: normal, high, low, critical>",
              "referenceRange": { "low": <number or null>, "high": <number or null> },
              "referenceRangeText": null,
              "qualitativeResult": null
            }
          ]
        }

        Rules:
        - Use null for any field you can't read confidently.
        - Infer flag from the reference range when not printed.
        - Skip rows that are headers, blank, or unreadable.
        """

        let body: [String: Any] = [
            "model": "claude-sonnet-4-5",
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64
                            ]
                        ],
                        ["type": "text", "text": prompt]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw ExtractionError.apiError(msg)
        }

        // Parse the Anthropic response envelope and pull out the text content.
        struct AnthropicResponse: Decodable {
            struct Block: Decodable { let type: String; let text: String? }
            let content: [Block]
        }

        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        guard let text = decoded.content.first(where: { $0.type == "text" })?.text else {
            throw ExtractionError.parseError("No text block in response")
        }

        // Strip any accidental markdown fences just in case.
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw ExtractionError.parseError("Empty model output")
        }

        // Validate it parses as LabResultsImport before handing back.
        _ = try JSONDecoder().decode(LabResultsImport.self, from: jsonData)
        return jsonData
    }
}
