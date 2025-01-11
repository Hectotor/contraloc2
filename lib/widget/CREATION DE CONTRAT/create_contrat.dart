import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CreateContrat {
  static Widget buildDateField(String label, TextEditingController controller,
      bool isStartDate, BuildContext context, Function selectDateTime) {
    if (isStartDate) {
      final now = DateTime.now();
      final formattedNow =
          DateFormat('EEEE d MMMM à HH:mm', 'fr_FR').format(now);
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
        ),
      ),
    );
  }

  static Widget buildDropdown(String typeLocation, Function onChanged) {
    return DropdownButtonFormField<String>(
      value: typeLocation,
      onChanged: (value) => onChanged(value),
      items: [
        const DropdownMenuItem(value: "Gratuite", child: Text("Gratuite")),
        const DropdownMenuItem(value: "Payante", child: Text("Payante")),
      ],
      decoration: InputDecoration(
        labelText: "Type de location",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static Widget buildFuelSlider(int pourcentageEssence, Function onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Niveau d'essence (%)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Slider(
          value: pourcentageEssence.toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          label: "$pourcentageEssence%",
          onChanged: (value) => onChanged(value),
        ),
      ],
    );
  }

  static Widget buildPrixLocationField(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true, // Make the field read-only
      decoration: InputDecoration(
        labelText: "Prix de la location par jour",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
