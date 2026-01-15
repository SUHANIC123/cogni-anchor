import 'package:cogni_anchor/data/reminder/reminder_model.dart';
import 'package:cogni_anchor/logic/bloc/reminder/reminder_bloc.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class AddReminderPage extends StatefulWidget {
  const AddReminderPage({super.key});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveReminder() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a reminder title.")),
      );
      return;
    }

    final now = DateTime.now();
    final timeAsDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final formattedTime = DateFormat('hh:mm a').format(timeAsDateTime);

    final newReminder = Reminder.draft(
      title: _titleController.text,
      date: DateFormat('dd MMM yyyy').format(_selectedDate),
      time: formattedTime,
    );

    context.read<ReminderBloc>().add(AddReminder(newReminder));
    Navigator.pop(context);
  }

  Widget _buildDateTimePicker({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22.sp),
            Gap(15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(label, fontSize: 12.sp, color: Colors.grey),
                  Gap(4.h),
                  AppText(value, fontSize: 16.sp, fontWeight: FontWeight.w500),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReminderBloc, ReminderState>(
      listener: (context, state) {
        if (state is ReminderError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: AppText("New Reminder",
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 18.sp),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primary),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText("Reminder Title",
                  fontSize: 14.sp, fontWeight: FontWeight.w600),
              Gap(8.h),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "E.g., Take medication",
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              Gap(30.h),
              _buildDateTimePicker(
                label: "Date",
                icon: Icons.calendar_today_outlined,
                value: DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                onTap: () => _selectDate(context),
              ),
              Gap(20.h),
              _buildDateTimePicker(
                label: "Time",
                icon: Icons.access_time_outlined,
                value: _selectedTime.format(context),
                onTap: () => _selectTime(context),
              ),
              Gap(50.h),
              BlocBuilder<ReminderBloc, ReminderState>(
                builder: (context, state) {
                  final isLoading = state is ReminderLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 55.h,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveReminder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : AppText("Save Reminder",
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
