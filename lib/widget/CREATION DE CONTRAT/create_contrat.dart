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

  static Widget buildDropdown(String typeLocation, Function onChanged) {
    final items = const [
      "Gratuite",
      "Payante",
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: typeLocation,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(color: Colors.black)),
          );
        }).toList(),
        onChanged: (String? newValue) {
          print('DEBUG DROPDOWN - Nouvelle valeur sélectionnée: $newValue');
          onChanged(newValue);
        },
        dropdownColor:
            Colors.white, // Ajout de cette ligne pour le fond du menu
        decoration: InputDecoration(
          labelText: "Type de location",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
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
