import CoreML

protocol RiskPredicting {
    func predict(pm2_5: Double, pm10: Double, carbonMonoxide: Double,
                 nitrogenDioxide: Double, ozone: Double, temperature: Double,
                 humidity: Double, windSpeed: Double, rain: Double) throws -> RiskPrediction
}

struct RiskPrediction {
    let label: String
    let probabilities: [String: Double]

    var riskLevel: RiskLevel? {
        RiskLevel(mlLabel: label)
    }
}

final class CoreMLRiskPredictor: RiskPredicting {
    private let model: RiskModel
    
    init() throws {
        model = try RiskModel(configuration: MLModelConfiguration())
    }
    
    func predict(pm2_5: Double, pm10: Double, carbonMonoxide: Double,
                 nitrogenDioxide: Double, ozone: Double, temperature: Double,
                 humidity: Double, windSpeed: Double, rain: Double) throws -> RiskPrediction {
        let output = try model.prediction(
            pm2_5: pm2_5, pm10: pm10, carbon_monoxide: carbonMonoxide,
            nitrogen_dioxide: nitrogenDioxide, ozone: ozone,
            temperature_2m: temperature, relative_humidity_2m: humidity,
            wind_speed_10m: windSpeed, rain: rain
        )
        return RiskPrediction(label: output.target, probabilities: output.classProbability)
    }
}
