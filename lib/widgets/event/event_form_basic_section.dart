import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact.dart';
import '../../models/event_type.dart';
import '../../utils/form_input_validators.dart';

class EventFormBasicSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController locationController;
  final TextEditingController descriptionController;
  final String? selectedEventTypeId;
  final ValueChanged<String?> onEventTypeChanged;
  final String? selectedCreatedByContactId;
  final ValueChanged<String?> onCreatedByContactChanged;
  final List<EventType> eventTypes;
  final List<Contact> contacts;

  const EventFormBasicSection({
    super.key,
    required this.titleController,
    required this.locationController,
    required this.descriptionController,
    required this.selectedEventTypeId,
    required this.onEventTypeChanged,
    required this.selectedCreatedByContactId,
    required this.onCreatedByContactChanged,
    required this.eventTypes,
    required this.contacts,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '基础信息',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('eventForm_titleField'),
              controller: titleController,
              maxLength: FormFieldLimits.eventTitle,
              decoration: const InputDecoration(
                labelText: '事件标题',
                hintText: '请输入事件标题',
              ),
              textInputAction: TextInputAction.next,
              validator: (value) => FormInputValidators.requiredText(
                value,
                fieldName: '事件标题',
                maxLength: FormFieldLimits.eventTitle,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String?>(
              key: const Key('eventForm_eventTypeField'),
              isExpanded: true,
              initialValue: selectedEventTypeId,
              decoration: const InputDecoration(labelText: '事件类型'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('未指定'),
                ),
                ...eventTypes.map(
                  (eventType) => DropdownMenuItem<String?>(
                    value: eventType.id,
                    child: Text(eventType.name),
                  ),
                ),
              ],
              onChanged: onEventTypeChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String?>(
              key: const Key('eventForm_createdByField'),
              isExpanded: true,
              initialValue: selectedCreatedByContactId,
              decoration: const InputDecoration(labelText: '创建人'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('未指定'),
                ),
                ...contacts.map(
                  (contact) => DropdownMenuItem<String?>(
                    value: contact.id,
                    child: Text(contact.name),
                  ),
                ),
              ],
              onChanged: onCreatedByContactChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('eventForm_locationField'),
              controller: locationController,
              maxLength: FormFieldLimits.eventLocation,
              decoration: const InputDecoration(
                labelText: '地点',
                hintText: '请输入事件地点',
              ),
              textInputAction: TextInputAction.next,
              validator: (value) => FormInputValidators.optionalText(
                value,
                fieldName: '地点',
                maxLength: FormFieldLimits.eventLocation,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('eventForm_descriptionField'),
              controller: descriptionController,
              maxLength: FormFieldLimits.eventDescription,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '补充事件背景、目标或跟进信息',
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 5,
              validator: (value) => FormInputValidators.optionalText(
                value,
                fieldName: '备注',
                maxLength: FormFieldLimits.eventDescription,
              ),
            ),
          ],
        ),
      ),
    );
  }
}