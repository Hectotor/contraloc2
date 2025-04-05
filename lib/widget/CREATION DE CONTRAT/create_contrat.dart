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
          "Niveau d'essence",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_gas_station, color: Colors.black),
                  const SizedBox(width: 10),
                  Text(
                    "Sélectionnez le niveau d'essence",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildEssenceOption("0", "Vide", pourcentageEssence, onChanged),
                  _buildEssenceOption("1/4", "1/4", pourcentageEssence, onChanged),
                  _buildEssenceOption("1/2", "1/2", pourcentageEssence, onChanged),
                  _buildEssenceOption("3/4", "3/4", pourcentageEssence, onChanged),
                  _buildEssenceOption("1", "Plein", pourcentageEssence, onChanged),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildEssenceOption(String value, String label, int currentValue, Function onChanged) {
    // Convertir la valeur actuelle en format comparable
    String currentValueStr;
    if (currentValue <= 0) {
      currentValueStr = "0";
    } else if (currentValue <= 25) {
      currentValueStr = "1/4";
    } else if (currentValue <= 50) {
      currentValueStr = "1/2";
    } else if (currentValue <= 75) {
      currentValueStr = "3/4";
    } else {
      currentValueStr = "1";
    }
    
    bool isSelected = currentValueStr == value;
    
    return InkWell(
      onTap: () {
        // Convertir la valeur sélectionnée en pourcentage
        String percentage;
        switch (value) {
          case "0": percentage = "0"; break;
          case "1/4": percentage = "25"; break;
          case "1/2": percentage = "50"; break;
          case "3/4": percentage = "75"; break;
          case "1": percentage = "100"; break;
          default: percentage = "0";
        }
        onChanged(int.parse(percentage));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black.withOpacity(0.3) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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

  static Widget buildAccompteField(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly
        ],
        decoration: InputDecoration(
          labelText: "Accompte",
          hintText: "Montant de l'accompte",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Ajout du bouton de validation
          suffixIcon: IconButton(
            icon: Icon(Icons.check_circle,
                color: Colors.grey[400]),
            onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
          ),
        ),
      ),
    );
  }
}