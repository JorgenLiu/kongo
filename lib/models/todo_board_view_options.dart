enum TodoGroupVisibility {
  activeOnly('进行中'),
  all('全部'),
  archivedOnly('已归档');

  const TodoGroupVisibility(this.label);

  final String label;
}

enum TodoItemFilter {
  all('全部事项'),
  pendingOnly('仅待处理'),
  completedOnly('仅已完成'),
  linkedOnly('仅已关联');

  const TodoItemFilter(this.label);

  final String label;
}

enum TodoItemSort {
  manual('手动顺序'),
  updatedAt('最近更新');

  const TodoItemSort(this.label);

  final String label;
}