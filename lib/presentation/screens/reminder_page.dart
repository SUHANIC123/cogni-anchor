import 'package:cogni_anchor/logic/reminder/reminder_bloc.dart'; // NEW
import 'package:cogni_anchor/data/models/reminder_model.dart';
import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/screens/add_reminder_page.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:cogni_anchor/presentation/widgets/reminder_page/reminder_child_card_widget.dart';
import 'package:cogni_anchor/presentation/widgets/reminder_page/reminder_main_card_widget.dart';
import 'package:cogni_anchor/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // NEW
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
    // 1. Trigger the data load event immediately
    context.read<ReminderBloc>().add(LoadReminders());
  }

  Widget? _buildFloatingActionButton() {
    if (widget.userModel == UserModel.caretaker) {
      return SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () {
            // 2. Remove callback, just push the page. The AddPage will dispatch the event.
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddReminderPage()));
          },
          backgroundColor: colors.appColor,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.h),
        child: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: colors.appColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20.r), bottomRight: Radius.circular(20.r)),
          ),
          title: AppText("Reminders", fontSize: 20.sp, color: Colors.white),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      
      // 3. Connect UI to BLoC State
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

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    Gap(30.h),
                    
                    // Show Upcoming card only if data exists
                    if (upcoming != null)
                      ReminderMainCardWidget(
                        title: upcoming.title, 
                        time: "${upcoming.date} ${upcoming.time}", // Combined date/time
                        color: colors.appColor
                      )
                    else 
                       const SizedBox.shrink(), // Or a "No upcoming reminders" placeholder

                    Gap(20.h),

                    Expanded(
                      child: reminders.isEmpty && upcoming == null 
                      ? Center(child: AppText("No reminders found"))
                      : ListView.builder(
                          itemCount: reminders.length,
                          itemBuilder: (context, index) {
                            final reminder = reminders[index];
                            return ReminderChildCardWidget(
                              title: reminder.title, 
                              date: reminder.date, 
                              time: reminder.time, 
                              color: colors.appColor
                            );
                          },
                        ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return const Center(child: Text("Something went wrong"));
        },
      ),
    );
  }
}