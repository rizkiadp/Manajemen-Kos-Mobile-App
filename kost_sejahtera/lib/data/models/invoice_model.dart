class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String tenantId;
  final String roomId;
  final String period; // "Jan 2024"
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String status; // 'paid', 'unpaid', 'overdue'
  final DateTime? paidAt;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.tenantId,
    required this.roomId,
    required this.period,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.status,
    this.paidAt,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      tenantId: json['tenantId'] as String,
      roomId: json['roomId'] as String,
      period: json['period'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      items: (json['items'] as List)
          .map((item) => InvoiceItem.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      paymentMethod: json['paymentMethod'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'tenantId': tenantId,
      'roomId': roomId,
      'period': period,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'status': status,
      'paidAt': paidAt?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isPaid => status == 'paid';
  bool get isUnpaid => status == 'unpaid';
  bool get isOverdue => status == 'overdue';
}

class InvoiceItem {
  final String description;
  final double amount;

  InvoiceItem({
    required this.description,
    required this.amount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
    };
  }
}
