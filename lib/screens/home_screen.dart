import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pomodoro_state.dart';
import '../providers/environment_provider.dart';
import '../providers/timer_provider.dart';
import '../services/ble_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenSettings;

  const HomeScreen({super.key, this.onOpenSettings});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedPort;
  String? _selectedBleId;
  bool _isConnecting = false;
  bool? _forceBleMode;

  void _showBleScannerSheet(
    BuildContext context,
    EnvironmentProvider envProvider,
  ) {
    if (!envProvider.isBleScanning &&
        envProvider.discoveredBleDevices.isEmpty) {
      envProvider.startBleScan();
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF222C3C)),
      ),
      builder: (sheetContext) {
        return Consumer<EnvironmentProvider>(
          builder: (ctx, env, _) {
            final devices = env.discoveredBleDevices;
            final isScanning = env.isBleScanning;
            final errorText = env.bleLastError;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HM-10 BLE SCANNER',
                              style: TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Service FFE0 • UART Characteristic FFE1',
                              style: TextStyle(
                                color: Color(0xFF8A99AD),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: const Color(0xFF63ADFF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (isScanning) {
                              env.stopBleScan();
                            } else {
                              env.startBleScan();
                            }
                          },
                          icon: isScanning
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF63ADFF),
                                  ),
                                )
                              : const Icon(
                                  Icons.bluetooth_searching_rounded,
                                  size: 15,
                                ),
                          label: Text(
                            isScanning ? 'Stop' : 'Scan',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1215),
                          border: Border.all(color: const Color(0xFF7F1D1D)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          errorText,
                          style: const TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (devices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            isScanning
                                ? 'Scanning for HM-10 (HMSoft / FFE0)...'
                                : 'No HM-10 BLE modules found nearby.\nEnsure HM-10 is powered (VCC -> 5V, GND -> GND).',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF8A99AD),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: devices.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final BleDiscoveredDevice dev = devices[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF151C28),
                                border: Border.all(
                                  color: dev.isHm10Candidate
                                      ? const Color(0xFF2E8BFF)
                                      : const Color(0xFF222C3C),
                                ),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.bluetooth_rounded,
                                    color: dev.isHm10Candidate
                                        ? const Color(0xFF63ADFF)
                                        : const Color(0xFF8A99AD),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                dev.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            if (dev.isHm10Candidate) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2E8BFF)
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'HM-10',
                                                  style: TextStyle(
                                                    color: Color(0xFF63ADFF),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${dev.id} • ${dev.rssi} dBm',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF8A99AD),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 30,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF2E8BFF),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () async {
                                        Navigator.of(sheetContext).pop();
                                        setState(() {
                                          _selectedBleId = dev.id;
                                          _isConnecting = true;
                                        });
                                        await env.connectToBleDevice(dev);
                                        if (mounted) {
                                          setState(() => _isConnecting = false);
                                        }
                                      },
                                      child: const Text(
                                        'Connect',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBleConnectionBar(
    BuildContext context,
    EnvironmentProvider envProvider,
  ) {
    final bleDevices = envProvider.discoveredBleDevices;
    if (_selectedBleId != null &&
        !bleDevices.any((d) => d.id == _selectedBleId)) {
      _selectedBleId = bleDevices.isNotEmpty ? bleDevices.first.id : null;
    } else if (_selectedBleId == null && bleDevices.isNotEmpty) {
      _selectedBleId = bleDevices.first.id;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151C28),
        border: Border.all(color: const Color(0xFF222C3C)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: envProvider.isBleConnected
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: envProvider.isBleConnected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.bluetooth_rounded,
            color: Color(0xFF63ADFF),
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: envProvider.isBleConnected || bleDevices.isEmpty
                ? GestureDetector(
                    onTap: () => _showBleScannerSheet(context, envProvider),
                    child: Text(
                      envProvider.isBleConnected
                          ? envProvider.activePortLabel
                          : (envProvider.isBleScanning
                              ? 'Scanning HM-10 BLE...'
                              : 'HM-10 BLE • Tap to Scan'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: envProvider.isBleConnected
                            ? Colors.white
                            : const Color(0xFF8A99AD),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBleId,
                      isDense: true,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF151C28),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      items: bleDevices
                          .map(
                            (dev) => DropdownMenuItem<String>(
                              value: dev.id,
                              child: Text(
                                '${dev.name} (${dev.rssi} dBm)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedBleId = val);
                      },
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 30,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: envProvider.isBleConnected
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF2E8BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isConnecting
                  ? null
                  : () async {
                      if (envProvider.isBleConnected) {
                        await envProvider.disconnectBle();
                        return;
                      }
                      final target = bleDevices.where(
                        (d) => d.id == _selectedBleId,
                      );
                      if (target.isEmpty) {
                        _showBleScannerSheet(context, envProvider);
                        return;
                      }
                      setState(() => _isConnecting = true);
                      await envProvider.connectToBleDevice(target.first);
                      if (mounted) {
                        setState(() => _isConnecting = false);
                      }
                    },
              child: Text(
                _isConnecting
                    ? '...'
                    : (envProvider.isBleConnected
                        ? 'Disconnect'
                        : (bleDevices.isEmpty ? 'Scan' : 'Connect')),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.bluetooth_searching_rounded,
                color: Color(0xFF8A99AD),
                size: 17,
              ),
              tooltip: 'Scan HM-10 BLE Devices',
              onPressed: () => _showBleScannerSheet(context, envProvider),
            ),
          ),
          if (!envProvider.isMobilePlatform) ...[
            const SizedBox(width: 2),
            SizedBox(
              width: 28,
              height: 30,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.usb_rounded,
                  color: Color(0xFF8A99AD),
                  size: 16,
                ),
                tooltip: 'Switch to USB Serial',
                onPressed: () {
                  setState(() => _forceBleMode = false);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final envProvider = context.watch<EnvironmentProvider>();
    final timerProvider = context.watch<TimerProvider>();

    final ports = envProvider.availablePorts;
    if (_selectedPort != null && !ports.contains(_selectedPort)) {
      _selectedPort = ports.isNotEmpty ? ports.first : null;
    } else if (_selectedPort == null && ports.isNotEmpty) {
      _selectedPort = ports.first;
    }

    final telemetry = envProvider.latestTelemetry;
    final evaluation = envProvider.latestEvaluation;

    final double lux = telemetry?.lux ?? 419.0;
    final double temp = telemetry?.temperature ?? 23.8;
    final double hum = telemetry?.humidity ?? 52.0;

    final bool isLightOk = evaluation?.isLightOptimal ?? true;
    final bool isTempOk = evaluation?.isTempOptimal ?? true;
    final bool isHumOk = evaluation?.isHumidityOptimal ?? true;

    final String bannerText = evaluation?.lightStatusMessage ??
        'Lighting optimal — ${lux.toStringAsFixed(0)} lx detected';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header (Wrapped in Expanded to prevent horizontal overflow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ARDUINO ENVIRONMENT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Workspace Status',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.9,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF151C28),
                  border: Border.all(color: const Color(0xFF222C3C)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF8A99AD),
                    size: 20,
                  ),
                  onPressed: widget.onOpenSettings,
                  tooltip: 'Settings',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Top Connection Bar (HM-10 BLE Scanner on Mobile / BLE mode, or USB COM Port Bar on Desktop)
          if (envProvider.isMobilePlatform ||
              envProvider.isBleConnected ||
              (_forceBleMode ?? false))
            _buildBleConnectionBar(context, envProvider)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF151C28),
                border: Border.all(color: const Color(0xFF222C3C)),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: envProvider.isConnected
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: envProvider.isConnected
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ports.isEmpty
                        ? Text(
                            envProvider.activePortLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8A99AD),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPort,
                              isDense: true,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF151C28),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              items: ports
                                  .map(
                                    (port) => DropdownMenuItem<String>(
                                      value: port,
                                      child: Text(
                                        port,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() => _selectedPort = val);
                              },
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 30,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: envProvider.isConnected
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF2E8BFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isConnecting
                          ? null
                          : () async {
                              if (envProvider.isConnected) {
                                await envProvider.disconnectPort();
                                return;
                              }
                              final target = _selectedPort ??
                                  (ports.isNotEmpty ? ports.first : null);
                              if (target == null) {
                                envProvider.refreshPorts();
                                return;
                              }
                              setState(() => _isConnecting = true);
                              await envProvider.connectToPort(target);
                              if (mounted) {
                                setState(() => _isConnecting = false);
                              }
                            },
                      child: Text(
                        _isConnecting
                            ? '...'
                            : (envProvider.isConnected
                                ? 'Disconnect'
                                : 'Connect'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF8A99AD),
                        size: 17,
                      ),
                      tooltip: 'Refresh Ports',
                      onPressed: () {
                        envProvider.refreshPorts();
                        final updated = envProvider.availablePorts;
                        setState(() {
                          if (updated.isNotEmpty &&
                              !updated.contains(_selectedPort)) {
                            _selectedPort = updated.first;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 28,
                    height: 30,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.bluetooth_rounded,
                        color: Color(0xFF63ADFF),
                        size: 17,
                      ),
                      tooltip: 'Switch to HM-10 BLE Mode',
                      onPressed: () {
                        setState(() => _forceBleMode = true);
                      },
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),

          // 3-Column Sensor Metric Grid
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Light',
                  value: '${lux.toStringAsFixed(0)} lx',
                  status: isLightOk ? 'Optimal' : 'Low Light',
                  icon: Icons.wb_sunny_outlined,
                  primaryColor: isLightOk
                      ? const Color(0xFF2E8BFF)
                      : const Color(0xFFEF4444),
                  statusColor: isLightOk
                      ? const Color(0xFF4AA8FF)
                      : const Color(0xFFF87171),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Temp',
                  value: '${temp.toStringAsFixed(1)} °C',
                  status: isTempOk ? 'Good' : 'Alert',
                  icon: Icons.thermostat_outlined,
                  primaryColor: const Color(0xFF10B981),
                  statusColor: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Humidity',
                  value: '${hum.toStringAsFixed(0)} %',
                  status: isHumOk ? 'Normal' : 'Alert',
                  icon: Icons.water_drop_outlined,
                  primaryColor: const Color(0xFFF59E0B),
                  statusColor: const Color(0xFFFBBF24),
                ),
              ),
            ],
          ),

          // Pomodoro Timer Section
          const SizedBox(height: 34),
          const Center(
            child: Text(
              'POMODORO TIMER',
              style: TextStyle(
                color: Color(0xFF718096),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Circular Conic Timer Ring
          Center(
            child: SizedBox(
              width: 228,
              height: 228,
              child: CustomPaint(
                painter: _TimerRingPainter(progress: timerProvider.progress),
                child: Center(
                  child: Container(
                    width: 212,
                    height: 212,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF141D2A),
                          Color(0xFF0B0F17),
                        ],
                        stops: [0.0, 0.7],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timerProvider.formattedTime,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white,
                            fontSize: 46,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -2.0,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timerProvider.phase == PomodoroPhase.focus
                              ? 'FOCUS'
                              : (timerProvider.phase == PomodoroPhase.longBreak
                                  ? 'LONG BREAK'
                                  : 'SHORT BREAK'),
                          style: TextStyle(
                            color: timerProvider.phase == PomodoroPhase.longBreak
                                ? const Color(0xFF10B981)
                                : const Color(0xFF718096),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 23),

          // Start & Reset Pill Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: timerProvider.toggle,
                child: Container(
                  width: 112,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8BFF),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E8BFF).withValues(alpha: 0.28),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    timerProvider.isRunning ? 'Pause' : 'Start',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: timerProvider.reset,
                child: Container(
                  width: 112,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151C28),
                    border: Border.all(color: const Color(0xFF2A3547)),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Color(0xFFB5C0D0),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Lighting Status Banner
          const SizedBox(height: 30),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: isLightOk
                  ? const Color(0xFF0D2821)
                  : const Color(0xFF2C1215),
              border: Border.all(
                color: isLightOk
                    ? const Color(0xFF185A47)
                    : const Color(0xFF7F1D1D),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isLightOk
                        ? const Color(0xFF66D8AD)
                        : const Color(0xFFF87171),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isLightOk
                            ? const Color(0xFF66D8AD)
                            : const Color(0xFFF87171),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    bannerText,
                    style: TextStyle(
                      color: isLightOk
                          ? const Color(0xFF66D8AD)
                          : const Color(0xFFF87171),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final IconData icon;
  final Color primaryColor;
  final Color statusColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.status,
    required this.icon,
    required this.primaryColor,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 13, 11, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18202D),
            Color(0xFF121923),
          ],
        ),
        border: Border.all(color: const Color(0xFF222C3C)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8A99AD),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 17,
                color: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 13),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: primaryColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;

  _TimerRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    final glowPaint = Paint()
      ..color = const Color(0xFF2E8BFF).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius, glowPaint);

    final trackPaint = Paint()
      ..color = const Color(0xFF1D2B3F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, trackPaint);

    final clampedProgress = progress.clamp(0.0, 1.0);
    if (clampedProgress > 0.0) {
      final sweepAngle = 2 * math.pi * clampedProgress;
      final progressPaint = Paint()
        ..color = const Color(0xFF2E8BFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );

      final dotAngle = -math.pi / 2 + sweepAngle;
      final dotCenter = Offset(
        center.dx + radius * math.cos(dotAngle),
        center.dy + radius * math.sin(dotAngle),
      );

      final dotGlowPaint = Paint()
        ..color = const Color(0xFF2E8BFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawCircle(dotCenter, 6, dotGlowPaint);

      final dotPaint = Paint()..color = const Color(0xFF72B6FF);
      canvas.drawCircle(dotCenter, 6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}