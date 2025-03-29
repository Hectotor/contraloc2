import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PopupVehiculeClient extends StatefulWidget {
  final Function(String, String) onSave;
  final String? immatriculationVehiculeClient;
  final String? kilometrageVehiculeClient;

  const PopupVehiculeClient({
    Key? key,
    required this.onSave,
    this.immatriculationVehiculeClient,
    this.kilometrageVehiculeClient,
  }) : super(key: key);

  @override
  State<PopupVehiculeClient> createState() => _PopupVehiculeClientState();
}

class _PopupVehiculeClientState extends State<PopupVehiculeClient> {
  final TextEditingController _immatriculationVehiculeClientController = TextEditingController();
  final TextEditingController _kilometrageVehiculeClientController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _immatriculationVehiculeClientController.text = widget.immatriculationVehiculeClient ?? '';
    _kilometrageVehiculeClientController.text = widget.kilometrageVehiculeClient ?? '';
  }

  @override
  void dispose() {
    _immatriculationVehiculeClientController.dispose();
    _kilometrageVehiculeClientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.directions_car,
                color: Color(0xFF08004D),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                "Véhicule du client",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08004D),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          
          // Immatriculation field
          TextField(
            controller: _immatriculationVehiculeClientController,
            decoration: InputDecoration(
              labelText: "Immatriculation",
              hintText: "Ex: AB-123-CD",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
              ),
              prefixIcon: const Icon(Icons.car_rental, color: Color(0xFF08004D)),
              floatingLabelStyle: const TextStyle(color: Color(0xFF08004D)),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          
          // Kilométrage field
          TextField(
            controller: _kilometrageVehiculeClientController,
            decoration: InputDecoration(
              labelText: "Kilométrage",
              hintText: "Ex: 45000",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
              ),
              prefixIcon: const Icon(Icons.speed, color: Color(0xFF08004D)),
              suffixText: "km",
              floatingLabelStyle: const TextStyle(color: Color(0xFF08004D)),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          const SizedBox(height: 30),
          
          // Save button
          ElevatedButton(
            onPressed: () {
              widget.onSave(
                _immatriculationVehiculeClientController.text.trim(),
                _kilometrageVehiculeClientController.text.trim(),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF08004D),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: const Text(
              "Enregistrer",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Function to show the vehicle dialog
Future<void> showVehiculeClientDialog({
  required BuildContext context,
  required Function(String, String) onSave,
  String? immatriculationVehiculeClient,
  String? kilometrageVehiculeClient,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return PopupVehiculeClient(
        onSave: onSave,
        immatriculationVehiculeClient: immatriculationVehiculeClient,
        kilometrageVehiculeClient: kilometrageVehiculeClient,
      );
    },
  );
}
