import 'package:cogni_anchor/data/auth/user_model.dart';
import 'package:cogni_anchor/data/reminder/reminder_model.dart';
import 'package:cogni_anchor/logic/bloc/reminder/reminder_bloc.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/screens/reminder/add_reminder_page.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:cogni_anchor/presentation/widgets/reminder/reminder_child_card_widget.dart';
import 'package:cogni_anchor/presentation/widgets/reminder/reminder_main_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class ReminderPage extends StatefulWidget {
  final UserModel userModel;
  const ReminderPage({super.key, required this.userModel});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderBloc>().add(LoadReminders());
    });
  }

  void _deleteReminder(Reminder reminder) {
    context.read<ReminderBloc>().add(DeleteReminder(reminder));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Reminder '${reminder.title}' deleted"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            context.read<ReminderBloc>().add(AddReminder(reminder));
          },
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (widget.userModel == UserModel.caretaker) {
      return FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: context.read<ReminderBloc>(),
                child: const AddReminderPage(),
              ),
            ),
          );

          if (mounted) {
            context.read<ReminderBloc>().add(LoadReminders());
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alarm, color: Colors.white),
        label: const Text("New Reminder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        automaticallyImplyLeading: false,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        ),
        title: AppText("Reminders", fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.w600),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: BlocConsumer<ReminderBloc, ReminderState>(
        listener: (context, state) {
          if (state is ReminderError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is ReminderLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RemindersLoaded) {
            final reminders = state.reminders;
            final upcoming = state.upcomingReminder;
            final isEmpty = reminders.isEmpty && upcoming == null;

            if (isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ReminderBloc>().add(LoadReminders());
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 100.h),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (upcoming != null) ...[
                          _sectionHeader("Next Up"),
                          Gap(12.h),
                          ReminderMainCardWidget(
                            title: upcoming.title,
                            time: "${upcoming.date} • ${upcoming.time}",
                            color: AppColors.primary,
                          ),
                          Gap(24.h),
                        ],
                        if (reminders.isNotEmpty) ...[
                          _sectionHeader("All Reminders"),
                          Gap(12.h),
                          ...reminders.map((reminder) => _buildDismissibleItem(reminder)),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text("Something went wrong"));
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: AppText(
        title,
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDismissibleItem(Reminder reminder) {
    final canDelete = widget.userModel == UserModel.caretaker;

    final card = ReminderChildCardWidget(
      title: reminder.title,
      date: reminder.date,
      time: reminder.time,
      color: Colors.blueGrey,
    );

    if (!canDelete) return Padding(padding: EdgeInsets.only(bottom: 12.h), child: card);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Dismissible(
        key: ValueKey(reminder.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.redAccent.shade100,
            borderRadius: BorderRadius.circular(12.r),
          ),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
        ),
        onDismissed: (_) => _deleteReminder(reminder),
        child: card,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.alarm_off_rounded, size: 60.sp, color: AppColors.primary),
          ),
          Gap(20.h),
          AppText("No reminders yet", fontSize: 18.sp, fontWeight: FontWeight.w600),
          Gap(8.h),
          AppText(
            "You're all caught up!\nAdd a new reminder to get started.",
            textAlign: TextAlign.center,
            color: Colors.grey,
            fontSize: 14.sp,
          ),
        ],
      ),
    );
  }
}
