enum GroupJoinRequestStatus { pending, accepted, declined, cancelled }

class GroupJoinRequest {
  final String id;
  final String issueId;
  final String groupId;
  final bool requestedByGroup;

  GroupJoinRequestStatus status;
  final DateTime requestedAt;
  DateTime? handledAt;

  GroupJoinRequest({
    required this.id,
    required this.issueId,
    required this.groupId,
    required this.requestedByGroup,
    GroupJoinRequestStatus? status,
    DateTime? requestedAt,
    this.handledAt,
  }) : status = status ?? GroupJoinRequestStatus.pending,
       requestedAt = requestedAt ?? DateTime.now();
}
