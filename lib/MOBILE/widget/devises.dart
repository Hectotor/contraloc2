import 'package:flutter/material.dart';

class Devise {
  final String code;
  final String label;
  final IconData icon;

  Devise({
    required this.code,
    required this.label,
    required this.icon,
  });
}

class DeviseWidget extends StatefulWidget {
  final TextEditingController controller;
  final String? initialValue;

  const DeviseWidget({
    Key? key,
    required this.controller,
    this.initialValue,
  }) : super(key: key);

  @override
  State<DeviseWidget> createState() => _DeviseWidgetState();
}

class _DeviseWidgetState extends State<DeviseWidget> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.controller.text.isEmpty ? widget.initialValue : widget.controller.text;
  }

  List<DropdownMenuItem<String>> _buildItems() {
    return [
      DropdownMenuItem(
        value: 'EUR',
        child: const Text('Euro (EUR - €)'),
      ),
      DropdownMenuItem(
        value: 'CHF',
        child: const Text('Franc suisse (CHF)'),
      ),
      DropdownMenuItem(
        value: 'DZD',
        child: const Text('Dinar algérien (DZD - DA)'),
      ),
      DropdownMenuItem(
        value: 'MAD',
        child: const Text('Dirham marocain (MAD - DH)'),
      ),
      DropdownMenuItem(
        value: 'TND',
        child: const Text('Dinar tunisien (TND)'),
      ),
      DropdownMenuItem(
        value: 'EGP',
        child: const Text('Livre égyptienne (EGP - LE)'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButton<String>(
        value: _selectedValue,
        hint: const Text('Sélectionnez une devise'),
        isExpanded: true,
        items: _buildItems(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedValue = newValue;
              widget.controller.text = newValue;
            });
          }
        },
        dropdownColor: Theme.of(context).cardColor,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 24,
      ),
    );
  }
}
