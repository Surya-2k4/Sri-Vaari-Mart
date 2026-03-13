import 'package:flutter/material.dart';

IconData getCategoryIcon(String icon) {
  switch (icon.toLowerCase()) {
    case 'sofa':
    case 'furniture':
    case 'chair':
      return Icons.chair;
    case 'bed':
      return Icons.bed;
    case 'dining':
      return Icons.table_bar;
    case 'mobile':
    case 'smartphone':
    case 'devices':
      return Icons.devices;
    case 'laptop':
      return Icons.laptop_mac;
    case 'appliance':
    case 'home_max':
      return Icons.home_max;
    default:
      return Icons.category;
  }
}
