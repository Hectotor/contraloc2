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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF08004D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, color: Color(0xFF08004D), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Véhicule du client",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _immatriculationVehiculeClientController,
                    decoration: InputDecoration(
                      labelText: 'Immatriculation',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _kilometrageVehiculeClientController,
                    decoration: InputDecoration(
                      labelText: 'Kilométrage',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixText: "km",
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 30),
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
            ),
          ],
        ),
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
