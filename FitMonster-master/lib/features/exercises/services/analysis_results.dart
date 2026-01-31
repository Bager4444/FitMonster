/// Общие классы результатов анализа для всех систем

/// Результат квантового анализа
class QuantumAnalysisResult {
  final double accuracy;
  final String analysis;
  final Map<String, dynamic> quantumData;
  
  const QuantumAnalysisResult({
    required this.accuracy,
    required this.analysis,
    required this.quantumData,
  });
}

/// Результат трансцендентного анализа
class TranscendentResult {
  final double transcendenceLevel;
  final String cosmicInsight;
  final Map<String, dynamic> transcendentData;
  
  const TranscendentResult({
    required this.transcendenceLevel,
    required this.cosmicInsight,
    required this.transcendentData,
  });
}

/// Результат мега-точного анализа
class MegaPrecisionResult {
  final double megaAccuracy;
  final String precisionAnalysis;
  final Map<String, dynamic> precisionData;
  
  const MegaPrecisionResult({
    required this.megaAccuracy,
    required this.precisionAnalysis,
    required this.precisionData,
  });
}

/// Результат мастер-анализа ИИ
class MasterAnalysisResult {
  final double masterScore;
  final String masterInsight;
  final Map<String, dynamic> masterData;
  
  const MasterAnalysisResult({
    required this.masterScore,
    required this.masterInsight,
    required this.masterData,
  });
}

/// Результат ультра-точного распознавания
class UltraPrecisionResult {
  final double ultraAccuracy;
  final String ultraAnalysis;
  final Map<String, dynamic> ultraData;
  
  const UltraPrecisionResult({
    required this.ultraAccuracy,
    required this.ultraAnalysis,
    required this.ultraData,
  });
}

/// Результат мастер ИИ
class MasterAIResult {
  final double aiScore;
  final String aiInsight;
  final Map<String, dynamic> aiData;
  
  const MasterAIResult({
    required this.aiScore,
    required this.aiInsight,
    required this.aiData,
  });
}