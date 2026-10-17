enum PlannerList { shopping, todo }

class PlannerItem {
  final String id;
  final String title;
  final PlannerList list;
  final bool isCompleted;

  const PlannerItem({
    required this.id,
    required this.title,
    required this.list,
    this.isCompleted = false,
  });

  factory PlannerItem.fromJson(Map<String, dynamic> json) {
    return PlannerItem(
      id: json['id'] as String,
      title: json['title'] as String,
      list: PlannerList.values.byName(json['list'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'list': list.name,
    'isCompleted': isCompleted,
  };
}
