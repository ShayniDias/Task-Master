class FAQ {
  final String question;
  final String answer;

  FAQ({required this.question, required this.answer});

  factory FAQ.fromJson(Map<dynamic, dynamic> json) {
    return FAQ(
      question: json['question'],
      answer: json['answer'],
    );
  }
}
