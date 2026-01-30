import 'package:flutter/material.dart';
import 'package:fitmonster/features/diet/data/allergens_database.dart';

/// Виджет для выбора аллергий
class AllergiesSelector extends StatelessWidget {
  final List<String> selectedAllergies;
  final Function(List<String>) onChanged;

  const AllergiesSelector({
    super.key,
    required this.selectedAllergies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Аллергии',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Выберите продукты, на которые у вас аллергия',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AllergensDatabase.commonAllergens.map((allergen) {
            final isSelected = selectedAllergies.contains(allergen);
            return FilterChip(
              label: Text(allergen),
              selected: isSelected,
              onSelected: (selected) {
                final newList = List<String>.from(selectedAllergies);
                if (selected) {
                  newList.add(allergen);
                } else {
                  newList.remove(allergen);
                }
                onChanged(newList);
              },
              selectedColor: Colors.red.withOpacity(0.2),
              checkmarkColor: Colors.red,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Виджет для выбора противопоказаний
class ContraindicationsSelector extends StatelessWidget {
  final List<String> selectedContraindications;
  final Function(List<String>) onChanged;

  const ContraindicationsSelector({
    super.key,
    required this.selectedContraindications,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medical_services, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Противопоказания',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Укажите заболевания или особые состояния',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AllergensDatabase.commonContraindications.map((condition) {
            final isSelected = selectedContraindications.contains(condition);
            return FilterChip(
              label: Text(condition),
              selected: isSelected,
              onSelected: (selected) {
                final newList = List<String>.from(selectedContraindications);
                if (selected) {
                  newList.add(condition);
                } else {
                  newList.remove(condition);
                }
                onChanged(newList);
              },
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
            );
          }).toList(),
        ),
      ],
    );
  }
}
