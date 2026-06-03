import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../providers/admin_provider.dart';

class AdminMapOverviewScreen extends StatefulWidget {
  const AdminMapOverviewScreen({super.key});

  @override
  State<AdminMapOverviewScreen> createState() =>
      _AdminMapOverviewScreenState();
}

class _AdminMapOverviewScreenState extends State<AdminMapOverviewScreen> {
  GoogleMapController? _mapController;

  // Default center: Gedung APB / Jakarta
  static const LatLng _defaultCenter = LatLng(-6.2088, 106.8456);

  Set<Marker> _buildMarkers(List<EmployeeClockInLocation> locations) {
    return locations.map((loc) {
      Color markerColor;
      switch (loc.status) {
        case AttendanceStatus.hadir:
          markerColor = Colors.green;
          break;
        case AttendanceStatus.telat:
          markerColor = Colors.orange;
          break;
        case AttendanceStatus.izin:
          markerColor = Colors.blue;
          break;
        default:
          markerColor = Colors.red;
      }

      final hue = markerColor == Colors.green
          ? BitmapDescriptor.hueGreen
          : markerColor == Colors.orange
              ? BitmapDescriptor.hueOrange
              : markerColor == Colors.blue
                  ? BitmapDescriptor.hueAzure
                  : BitmapDescriptor.hueRed;

      return Marker(
        markerId: MarkerId(loc.userId),
        position: LatLng(loc.latitude, loc.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: loc.userName,
          snippet:
              '${_fmtTime(loc.timestamp)} — ${_statusLabel(loc.status)}',
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final locations = admin.clockInLocations;
    final markers = _buildMarkers(locations);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Peta Kehadiran Real-time',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
            onPressed: admin.loadDashboardStats,
          ),
        ],
      ),
      body: Column(
        children: [
          // Legend
          _buildLegend(),
          // Map
          Expanded(
            child: admin.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.secondary))
                : Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: (ctrl) => _mapController = ctrl,
                        initialCameraPosition: const CameraPosition(
                          target: _defaultCenter,
                          zoom: 12,
                        ),
                        markers: markers,
                        myLocationButtonEnabled: false,
                        mapType: MapType.normal,
                        mapToolbarEnabled: false,
                      ),
                      // Employee count badge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCard,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(60),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_rounded,
                                  color: AppColors.secondary, size: 16),
                              const SizedBox(width: 6),
                              Text('${locations.length} hadir',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      if (locations.isEmpty)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Belum ada karyawan yang absen hari ini',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          // Employee location list
          if (locations.isNotEmpty) _buildLocationList(locations),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      color: AppColors.primaryCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendDot('Hadir', Colors.green),
          _legendDot('Telat', Colors.orange),
          _legendDot('Izin', Colors.blue),
          _legendDot('Alpha', Colors.red),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      );

  Widget _buildLocationList(List<EmployeeClockInLocation> locations) {
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        color: AppColors.primaryCard,
        border: Border(top: BorderSide(color: AppColors.primaryLight)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: locations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) => _locationChip(locations[i]),
      ),
    );
  }

  Widget _locationChip(EmployeeClockInLocation loc) {
    final color = _statusColor(loc.status);
    return GestureDetector(
      onTap: () {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(loc.latitude, loc.longitude),
            15,
          ),
        );
      },
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.userName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_fmtTime(loc.timestamp),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(_statusLabel(loc.status),
                style:
                    TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Row(
              children: [
                Icon(Icons.my_location_rounded,
                    color: AppColors.textMuted, size: 11),
                SizedBox(width: 3),
                Text('Tap untuk zoom',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _statusLabel(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.hadir:
        return 'Hadir';
      case AttendanceStatus.telat:
        return 'Telat';
      case AttendanceStatus.izin:
        return 'Izin';
      case AttendanceStatus.alpha:
        return 'Alpha';
    }
  }

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.hadir:
        return AppColors.success;
      case AttendanceStatus.telat:
        return AppColors.warning;
      case AttendanceStatus.izin:
        return AppColors.info;
      case AttendanceStatus.alpha:
        return AppColors.error;
    }
  }
}
