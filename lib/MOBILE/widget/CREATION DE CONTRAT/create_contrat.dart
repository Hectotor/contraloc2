import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CreateContrat {
  static Widget buildDateField(String label, TextEditingController controller,
      bool isStartDate, BuildContext context, Function selectDateTime) {
    if (isStartDate && controller.text.isEmpty) {
      final now = DateTime.now();
      final formattedNow = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(now);
      controller.text = formattedNow;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () =>
            selectDateTime(controller), // Updated to select date and time
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static Widget buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Ajout du bouton de validation
          suffixIcon: IconButton(
            icon: Icon(Icons.check_circle,
                color: Colors.grey[400]), // Changé à gris clair
            onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
          ),
        ),
      ),
    );
  }
}