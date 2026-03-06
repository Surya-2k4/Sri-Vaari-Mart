import 'package:flutter/material.dart';

IconData getCategoryIcon(String icon) {
  switch (icon) {
    case 'sofa':
      return Icons.weekend;
    case 'bed':
      return Icons.bed;
    case 'dining':
      return Icons.table_bar;
    case 'mobile':
      return Icons.smartphone;
    case 'laptop':
      return Icons.laptop_mac;
    case 'appliance':
      return Icons.kitchen;
    default:
      return Icons.category;
  }
}
