import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'SGI'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get navProjects;

  /// No description provided for @navGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get navGoals;

  /// No description provided for @navNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @tag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get tag;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get createTask;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get createProject;

  /// No description provided for @createGoal.
  ///
  /// In en, this message translates to:
  /// **'New Goal'**
  String get createGoal;

  /// No description provided for @createNote.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get createNote;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get editProject;

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get editGoal;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get searchTasks;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusInReview.
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get statusInReview;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDueDate;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @subtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get subtasks;

  /// No description provided for @addSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add subtask'**
  String get addSubtask;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get taskCompleted;

  /// No description provided for @taskRestored.
  ///
  /// In en, this message translates to:
  /// **'Task restored'**
  String get taskRestored;

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task moved to trash'**
  String get taskDeleted;

  /// No description provided for @projectCompleted.
  ///
  /// In en, this message translates to:
  /// **'Project completed'**
  String get projectCompleted;

  /// No description provided for @goalAchieved.
  ///
  /// In en, this message translates to:
  /// **'Goal achieved'**
  String get goalAchieved;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @itemRestored.
  ///
  /// In en, this message translates to:
  /// **'Item restored'**
  String get itemRestored;

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Moved to trash'**
  String get itemDeleted;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @emptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get emptyTrash;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @permanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get permanentlyDelete;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @debug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @totalTasks.
  ///
  /// In en, this message translates to:
  /// **'Total tasks'**
  String get totalTasks;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTasks;

  /// No description provided for @pendingTasks.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTasks;

  /// No description provided for @overdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueTasks;

  /// No description provided for @activeProjects.
  ///
  /// In en, this message translates to:
  /// **'Active projects'**
  String get activeProjects;

  /// No description provided for @activeGoals.
  ///
  /// In en, this message translates to:
  /// **'Active goals'**
  String get activeGoals;

  /// No description provided for @recentNotes.
  ///
  /// In en, this message translates to:
  /// **'Recent notes'**
  String get recentNotes;

  /// No description provided for @quickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get quickStats;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @itemCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get itemCreated;

  /// No description provided for @itemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get itemUpdated;

  /// No description provided for @emptyState.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyState;

  /// No description provided for @emptyStateDescription.
  ///
  /// In en, this message translates to:
  /// **'Start by creating your first item'**
  String get emptyStateDescription;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get unexpectedError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get tryAgain;

  /// No description provided for @completed_on.
  ///
  /// In en, this message translates to:
  /// **'Completed on'**
  String get completed_on;

  /// No description provided for @created_on.
  ///
  /// In en, this message translates to:
  /// **'Created on'**
  String get created_on;

  /// No description provided for @due_on.
  ///
  /// In en, this message translates to:
  /// **'Due on'**
  String get due_on;

  /// No description provided for @updated_on.
  ///
  /// In en, this message translates to:
  /// **'Updated on'**
  String get updated_on;

  /// No description provided for @sortPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get sortPriority;

  /// No description provided for @sortDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get sortDueDate;

  /// No description provided for @sortCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created date'**
  String get sortCreatedAt;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortTitle;

  /// No description provided for @sortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get sortAlphabetical;

  /// No description provided for @filterPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority filter'**
  String get filterPriority;

  /// No description provided for @filterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status filter'**
  String get filterStatus;

  /// No description provided for @filterProject.
  ///
  /// In en, this message translates to:
  /// **'Project filter'**
  String get filterProject;

  /// No description provided for @filterDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date filter'**
  String get filterDueDate;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get filterAll;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get filterToday;

  /// No description provided for @filterThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Due this week'**
  String get filterThisWeek;

  /// No description provided for @filterOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get filterOverdue;

  /// No description provided for @filterNoDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get filterNoDate;

  /// No description provided for @onlyWithDescription.
  ///
  /// In en, this message translates to:
  /// **'With description'**
  String get onlyWithDescription;

  /// No description provided for @onlyWithProject.
  ///
  /// In en, this message translates to:
  /// **'With project'**
  String get onlyWithProject;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @allItems.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get allItems;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @objective.
  ///
  /// In en, this message translates to:
  /// **'Objective'**
  String get objective;

  /// No description provided for @metric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get metric;

  /// No description provided for @horizon.
  ///
  /// In en, this message translates to:
  /// **'Horizon'**
  String get horizon;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @emoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emoji;

  /// No description provided for @notebook.
  ///
  /// In en, this message translates to:
  /// **'Notebook'**
  String get notebook;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @focusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get focusMode;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @todayView.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayView;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importData;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear all data'**
  String get clearAllData;

  /// No description provided for @projectTasks.
  ///
  /// In en, this message translates to:
  /// **'Project tasks'**
  String get projectTasks;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get noTasks;

  /// No description provided for @tagColor.
  ///
  /// In en, this message translates to:
  /// **'Tag color'**
  String get tagColor;

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagName;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get searchResults;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @searchInTasks.
  ///
  /// In en, this message translates to:
  /// **'Search in tasks'**
  String get searchInTasks;

  /// No description provided for @searchInNotes.
  ///
  /// In en, this message translates to:
  /// **'Search in notes'**
  String get searchInNotes;

  /// No description provided for @searchInProjects.
  ///
  /// In en, this message translates to:
  /// **'Search in projects'**
  String get searchInProjects;

  /// No description provided for @searchInGoals.
  ///
  /// In en, this message translates to:
  /// **'Search in goals'**
  String get searchInGoals;

  /// No description provided for @hapticEnabled.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get hapticEnabled;

  /// No description provided for @skeletonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get skeletonLoading;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get pageOf;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @brainDump.
  ///
  /// In en, this message translates to:
  /// **'Brain Dump'**
  String get brainDump;

  /// No description provided for @quickCapture.
  ///
  /// In en, this message translates to:
  /// **'Quick Capture'**
  String get quickCapture;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @taskCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get taskCompletionRate;

  /// No description provided for @tasksByPriority.
  ///
  /// In en, this message translates to:
  /// **'Tasks by priority'**
  String get tasksByPriority;

  /// No description provided for @tasksByStatus.
  ///
  /// In en, this message translates to:
  /// **'Tasks by status'**
  String get tasksByStatus;

  /// No description provided for @projectsProgress.
  ///
  /// In en, this message translates to:
  /// **'Projects progress'**
  String get projectsProgress;

  /// No description provided for @goalsProgress.
  ///
  /// In en, this message translates to:
  /// **'Goals progress'**
  String get goalsProgress;

  /// No description provided for @productivityTrend.
  ///
  /// In en, this message translates to:
  /// **'Productivity trend'**
  String get productivityTrend;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @syncCloud.
  ///
  /// In en, this message translates to:
  /// **'Sync to cloud'**
  String get syncCloud;

  /// No description provided for @cloudNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync not available in offline mode'**
  String get cloudNotAvailable;

  /// No description provided for @widgets.
  ///
  /// In en, this message translates to:
  /// **'Home widgets'**
  String get widgets;

  /// No description provided for @recurringReminders.
  ///
  /// In en, this message translates to:
  /// **'Recurring reminders'**
  String get recurringReminders;

  /// No description provided for @customThemes.
  ///
  /// In en, this message translates to:
  /// **'Custom themes'**
  String get customThemes;

  /// No description provided for @goalMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get goalMonthly;

  /// No description provided for @goalQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get goalQuarterly;

  /// No description provided for @goalYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get goalYearly;

  /// No description provided for @moveToTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get moveToTrashTitle;

  /// No description provided for @moveToTrashContent.
  ///
  /// In en, this message translates to:
  /// **'Move goal to trash?'**
  String get moveToTrashContent;

  /// No description provided for @sortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sortRecent;

  /// No description provided for @goalAddProgress.
  ///
  /// In en, this message translates to:
  /// **'Add progress'**
  String get goalAddProgress;

  /// No description provided for @goalAmountToAdd.
  ///
  /// In en, this message translates to:
  /// **'Amount to add'**
  String get goalAmountToAdd;

  /// No description provided for @goalAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get goalAdd;

  /// No description provided for @goalUpdateProgress.
  ///
  /// In en, this message translates to:
  /// **'Update progress'**
  String get goalUpdateProgress;

  /// No description provided for @goalNameHint.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goalNameHint;

  /// No description provided for @goalProgressMetric.
  ///
  /// In en, this message translates to:
  /// **'Progress metric'**
  String get goalProgressMetric;

  /// No description provided for @goalCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get goalCurrent;

  /// No description provided for @goalTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get goalTarget;

  /// No description provided for @goalChooseColor.
  ///
  /// In en, this message translates to:
  /// **'Choose color'**
  String get goalChooseColor;

  /// No description provided for @goalLinkedProjects.
  ///
  /// In en, this message translates to:
  /// **'Linked projects'**
  String get goalLinkedProjects;

  /// No description provided for @goalNoLinkedProjects.
  ///
  /// In en, this message translates to:
  /// **'No linked projects'**
  String get goalNoLinkedProjects;

  /// No description provided for @goalNoTagsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tags available. Create one from Settings.'**
  String get goalNoTagsAvailable;

  /// No description provided for @goalPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get goalPaused;

  /// No description provided for @goalAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get goalAbandoned;

  /// No description provided for @goalNeedsName.
  ///
  /// In en, this message translates to:
  /// **'Goal needs a name'**
  String get goalNeedsName;

  /// No description provided for @goalNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get goalNotStarted;

  /// No description provided for @goalInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get goalInProgress;

  /// No description provided for @goalProgressCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get goalProgressCompleted;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @allNotebooks.
  ///
  /// In en, this message translates to:
  /// **'All notebooks'**
  String get allNotebooks;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get gridView;

  /// No description provided for @emptyNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get emptyNotes;

  /// No description provided for @emptyNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture your ideas, references and thoughts'**
  String get emptyNotesSubtitle;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @notePinned.
  ///
  /// In en, this message translates to:
  /// **'Note pinned'**
  String get notePinned;

  /// No description provided for @noteUnpinned.
  ///
  /// In en, this message translates to:
  /// **'Note unpinned'**
  String get noteUnpinned;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'pinned'**
  String get pinned;

  /// No description provided for @notebooksLabel.
  ///
  /// In en, this message translates to:
  /// **'notebooks'**
  String get notebooksLabel;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardTitle;

  /// No description provided for @discardContent.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to leave?'**
  String get discardContent;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @notesDeleted.
  ///
  /// In en, this message translates to:
  /// **'note(s) deleted'**
  String get notesDeleted;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeleted;

  /// No description provided for @notesUndoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note \"{title}\" deleted'**
  String notesUndoDeleted(Object title);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @selectNotebook.
  ///
  /// In en, this message translates to:
  /// **'Select notebook'**
  String get selectNotebook;

  /// No description provided for @moveToNotebook.
  ///
  /// In en, this message translates to:
  /// **'Move to notebook'**
  String get moveToNotebook;

  /// No description provided for @chooseEmoji.
  ///
  /// In en, this message translates to:
  /// **'Choose Emoji'**
  String get chooseEmoji;

  /// No description provided for @tapToAssignTags.
  ///
  /// In en, this message translates to:
  /// **'Tap to assign tags to this note'**
  String get tapToAssignTags;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get noTags;

  /// No description provided for @createTags.
  ///
  /// In en, this message translates to:
  /// **'Create tags'**
  String get createTags;

  /// No description provided for @manageTags.
  ///
  /// In en, this message translates to:
  /// **'Manage tags'**
  String get manageTags;

  /// No description provided for @createNewTag.
  ///
  /// In en, this message translates to:
  /// **'Create new tag'**
  String get createNewTag;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @searchNotebook.
  ///
  /// In en, this message translates to:
  /// **'Search notebook...'**
  String get searchNotebook;

  /// No description provided for @newNotebook.
  ///
  /// In en, this message translates to:
  /// **'New notebook...'**
  String get newNotebook;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
