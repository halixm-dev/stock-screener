import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/screen_signal_config.dart';
import '../../domain/indicator_schema.dart';
import '../../state/config_cubit.dart';
import '../../state/config_state.dart';
import '../../application/notification_service.dart';
import 'package:workmanager/workmanager.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Indicator Config')),
      body: BlocBuilder<ConfigCubit, ConfigState>(
        builder: (context, state) {
          final config = state.config;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildGeneralSettingsSection(context, state),
              const SizedBox(height: 24),
              _buildRoutingSection(context, config),
              const SizedBox(height: 24),
              _buildParametersSection(context, config),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGeneralSettingsSection(BuildContext context, ConfigState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Background Scans'),
              subtitle: const Text(
                'Run scans every hour and notify of fresh signals',
              ),
              value: state.isBackgroundScanEnabled,
              onChanged: (val) async {
                context.read<ConfigCubit>().setBackgroundScanEnabled(val);
                if (val) {
                  // Request permissions
                  final notif = NotificationService();
                  await notif.initialize();
                  await notif.requestPermissions();

                  // Register task
                  Workmanager().registerPeriodicTask(
                    "1",
                    "backgroundScreenerTask",
                    frequency: const Duration(hours: 1),
                  );
                } else {
                  Workmanager().cancelAll();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutingSection(BuildContext context, ScreenSignalConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signal Routing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Leading Indicator'),
              initialValue: config.leadingIndicator,
              items: indicatorRegistry.keys.map((key) {
                return DropdownMenuItem(value: key, child: Text(key));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  final newConfirmations = List<String>.from(
                    config.confirmations,
                  )..remove(val);
                  context.read<ConfigCubit>().updateConfig(
                    config.copyWith(
                      leadingIndicator: val,
                      confirmations: newConfirmations,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Confirmations (AND Gate)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: indicatorRegistry.keys
                  .where((k) => k != config.leadingIndicator)
                  .map((key) {
                    final isSelected = config.confirmations.contains(key);
                    return FilterChip(
                      label: Text(key),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newConfirmations = List<String>.from(
                          config.confirmations,
                        );
                        if (selected) {
                          newConfirmations.add(key);
                        } else {
                          newConfirmations.remove(key);
                        }
                        context.read<ConfigCubit>().updateConfig(
                          config.copyWith(confirmations: newConfirmations),
                        );
                      },
                    );
                  })
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersSection(
    BuildContext context,
    ScreenSignalConfig config,
  ) {
    final activeIndicators = [config.leadingIndicator, ...config.confirmations];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Parameters', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...activeIndicators.map((indicatorName) {
          final schema = indicatorRegistry[indicatorName];
          if (schema == null || schema.parameters.isEmpty) {
            return const SizedBox.shrink();
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: ExpansionTile(
              title: Text(indicatorName),
              initiallyExpanded: true,
              children: schema.parameters.entries.map((entry) {
                final paramKey = entry.key;
                final paramDef = entry.value;

                final currentParams = config.parameters[indicatorName] ?? {};
                final currentValue = currentParams.containsKey(paramKey)
                    ? currentParams[paramKey]
                    : _getDefaultValue(paramDef);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: _buildParamWidget(
                    context,
                    config,
                    indicatorName,
                    paramKey,
                    paramDef,
                    currentValue,
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  dynamic _getDefaultValue(ConfigParam param) {
    return switch (param) {
      IntParam p => p.defaultValue,
      DoubleParam p => p.defaultValue,
      BoolParam p => p.defaultValue,
      ChoiceParam p => p.defaultValue,
    };
  }

  Widget _buildParamWidget(
    BuildContext context,
    ScreenSignalConfig config,
    String indicatorName,
    String paramKey,
    ConfigParam paramDef,
    dynamic currentValue,
  ) {
    void updateValue(dynamic newValue) {
      final newParams = Map<String, Map<String, dynamic>>.from(
        config.parameters,
      );
      newParams[indicatorName] = Map<String, dynamic>.from(
        newParams[indicatorName] ?? {},
      );
      newParams[indicatorName]![paramKey] = newValue;

      context.read<ConfigCubit>().updateConfig(
        config.copyWith(parameters: newParams),
      );
    }

    return switch (paramDef) {
      IntParam p => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${p.label}: ${(currentValue as int?) ?? p.defaultValue}'),
          Slider(
            value: (currentValue ?? p.defaultValue).toDouble(),
            min: p.min.toDouble(),
            max: p.max.toDouble(),
            divisions: p.max > p.min ? p.max - p.min : 1,
            onChanged: (val) => updateValue(val.round()),
          ),
        ],
      ),
      DoubleParam p => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${p.label}: ${((currentValue as double?) ?? p.defaultValue).toStringAsFixed(2)}',
          ),
          Slider(
            value: currentValue ?? p.defaultValue,
            min: p.min,
            max: p.max,
            onChanged: updateValue,
          ),
        ],
      ),
      BoolParam p => SwitchListTile(
        title: Text(p.label),
        value: (currentValue as bool?) ?? p.defaultValue,
        onChanged: updateValue,
      ),
      ChoiceParam p => DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: p.label),
        initialValue: (currentValue as String?) ?? p.defaultValue,
        items: p.options
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
            .toList(),
        onChanged: (val) {
          if (val != null) updateValue(val);
        },
      ),
    };
  }
}
