// lib/views/tela_mapa_estudos.dart  ← NOVO na Parte 3

// Mostra um mapa interativo (flutter_map + tiles OpenStreetMap) com marcadores
// nos locais onde o usuário estudou, além de uma lista resumida abaixo.

// Recurso nativo (GPS) + API (geocodificação) se encontram aqui: os pontos do
// mapa vêm de coordenadas capturadas pelo GPS e nomeadas pela API Nominatim.


import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../controllers/mapa_controller.dart';
import '../controllers/pomodoro_controller.dart';
import '../core/constants.dart';
import '../models/local_estudo.dart';

class TelaMapaEstudos extends StatefulWidget {
  const TelaMapaEstudos({super.key});

  @override
  State<TelaMapaEstudos> createState() => _TelaMapaEstudosState();
}

class _TelaMapaEstudosState extends State<TelaMapaEstudos> {
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Agrega os locais a partir das sessões já carregadas no PomodoroController.
    final sessoes = context.read<PomodoroController>().sessoes;
    context.read<MapaController>().carregar(sessoes);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Centro inicial do mapa: o local mais estudado, ou um fallback (Brasil).
  LatLng _centro(List<LocalEstudo> locais) {
    if (locais.isNotEmpty) {
      return LatLng(locais.first.latitude, locais.first.longitude);
    }
    return const LatLng(-14.235, -51.925); // centro aproximado do Brasil
  }

  @override
  Widget build(BuildContext context) {
    final mapa = context.watch<MapaController>();
    final locais = mapa.locais;

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Estudos')),
      body: locais.isEmpty
          ? _EstadoVazio()
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _centro(locais),
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.mini_pomodoro',
                      ),
                      MarkerLayer(
                        markers: [
                          for (final l in locais)
                            Marker(
                              point: LatLng(l.latitude, l.longitude),
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.deepOrange,
                                size: 44,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: locais.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final l = locais[i];
                      return ListTile(
                        leading: const Icon(Icons.location_on,
                            color: Colors.deepOrange),
                        title: Text(
                          l.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${l.totalSessoes} sessão(ões)',
                        ),
                        trailing: Text(
                          formatarDuracao(l.totalMinutos),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepOrange,
                          ),
                        ),
                        onTap: () => _mapController.move(
                          LatLng(l.latitude, l.longitude),
                          16,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nenhum local registrado ainda.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Conclua uma sessão de estudo com o GPS ativo para que ela '
              'apareça no mapa.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
