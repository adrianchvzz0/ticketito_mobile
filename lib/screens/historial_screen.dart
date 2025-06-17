import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({Key? key}) : super(key: key);

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _purchases = [];
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _fetchPurchases();
  }

  Future<void> _fetchPurchases() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('purchases')
          .where('userId', isEqualTo: user!.uid)
          .get();
      final purchasesData = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      setState(() {
        _purchases = purchasesData;
      });
    } catch (e) {
      print('Error obteniendo historial de compras: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Boletos',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              fontFamily: 'Poppins',
            )),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF88)))
          : _purchases.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes boletos comprados.',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _purchases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final p = _purchases[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF84D7B0), width: 1),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['eventTitle'] ?? 'Evento',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fecha: ${p['eventDate'] ?? '-'}',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'Poppins',
                                fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Zona: ${p['zone'] ?? '-'}',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'Poppins',
                                fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cantidad: ${p['ticketQuantity'] ?? 1}',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'Poppins',
                                fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: ${p['totalPrice'] != null ? "\$${p['totalPrice']}" : '-'}',
                            style: const TextStyle(
                                color: Color(0xFF00FF88),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
