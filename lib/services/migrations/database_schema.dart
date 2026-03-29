// 数据库 DDL 常量：建表语句与索引创建语句。
//
// 被 DatabaseService 在 onCreate 和 onUpgrade 中引用。

// ──────────────────── 建表语句 ────────────────────

const String createContactsTable = '''
CREATE TABLE contacts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  notes TEXT,
  avatarPath TEXT,
  createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER
)
''';

const String createTagsTable = '''
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  color TEXT,
  createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER
)
''';

const String createContactTagsTable = '''
CREATE TABLE contact_tags (
  id TEXT PRIMARY KEY,
  contactId TEXT NOT NULL,
  tagId TEXT NOT NULL,
  addedAt INTEGER NOT NULL,
  FOREIGN KEY (contactId) REFERENCES contacts(id) ON DELETE CASCADE,
  FOREIGN KEY (tagId) REFERENCES tags(id) ON DELETE CASCADE,
  UNIQUE(contactId, tagId)
)
''';

const String createEventTypesTable = '''
CREATE TABLE event_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon TEXT,
  color TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
)
''';

const String createEventsTable = '''
CREATE TABLE events (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  eventTypeId TEXT,
  status TEXT NOT NULL DEFAULT 'planned',
  startAt INTEGER,
  endAt INTEGER,
  location TEXT,
  description TEXT,
  reminderEnabled INTEGER NOT NULL DEFAULT 0,
  reminderAt INTEGER,
  createdByContactId TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,
  FOREIGN KEY (eventTypeId) REFERENCES event_types(id),
  FOREIGN KEY (createdByContactId) REFERENCES contacts(id)
)
''';

const String createEventParticipantsTable = '''
CREATE TABLE event_participants (
  id TEXT PRIMARY KEY,
  eventId TEXT NOT NULL,
  contactId TEXT NOT NULL,
  role TEXT,
  addedAt INTEGER NOT NULL,
  FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE,
  FOREIGN KEY (contactId) REFERENCES contacts(id) ON DELETE CASCADE,
  UNIQUE(eventId, contactId)
)
''';

const String createEventSummariesTable = '''
CREATE TABLE event_summaries (
  id TEXT PRIMARY KEY,
  eventId TEXT NOT NULL,
  title TEXT,
  content TEXT NOT NULL,
  summaryType TEXT NOT NULL DEFAULT 'manual',
  version INTEGER NOT NULL DEFAULT 1,
  source TEXT NOT NULL DEFAULT 'manual',
  createdByContactId TEXT,
  aiJobId TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE,
  FOREIGN KEY (createdByContactId) REFERENCES contacts(id)
)
''';

const String createDailySummariesTable = '''
CREATE TABLE daily_summaries (
  id TEXT PRIMARY KEY,
  summaryDate INTEGER NOT NULL UNIQUE,
  todaySummary TEXT NOT NULL DEFAULT '',
  tomorrowPlan TEXT NOT NULL DEFAULT '',
  source TEXT NOT NULL DEFAULT 'manual',
  createdByContactId TEXT,
  aiJobId TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,
  FOREIGN KEY (createdByContactId) REFERENCES contacts(id)
)
''';

const String createAttachmentsTable = '''
CREATE TABLE attachments (
  id TEXT PRIMARY KEY,
  fileName TEXT NOT NULL,
  originalFileName TEXT,
  storagePath TEXT NOT NULL,
  storageMode TEXT NOT NULL DEFAULT 'managed',
  sourcePath TEXT,
  managedPath TEXT,
  snapshotPath TEXT,
  mimeType TEXT,
  extension TEXT,
  sizeBytes INTEGER NOT NULL,
  originalSizeBytes INTEGER,
  managedSizeBytes INTEGER,
  checksum TEXT,
  previewText TEXT,
  previewStatus TEXT NOT NULL DEFAULT 'none',
  previewUpdatedAt INTEGER,
  previewError TEXT,
  sourceStatus TEXT NOT NULL DEFAULT 'available',
  sourceLastVerifiedAt INTEGER,
  importPolicy TEXT,
  createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER
)
''';

const String createAttachmentLinksTable = '''
CREATE TABLE attachment_links (
  id TEXT PRIMARY KEY,
  attachmentId TEXT NOT NULL,
  ownerType TEXT NOT NULL,
  ownerId TEXT NOT NULL,
  label TEXT,
  addedAt INTEGER NOT NULL,
  FOREIGN KEY (attachmentId) REFERENCES attachments(id) ON DELETE CASCADE,
  UNIQUE(attachmentId, ownerType, ownerId)
)
''';

const String createAiJobsTable = '''
CREATE TABLE ai_jobs (
  id TEXT PRIMARY KEY,
  feature TEXT NOT NULL,
  provider TEXT NOT NULL,
  model TEXT,
  targetType TEXT NOT NULL,
  targetId TEXT NOT NULL,
  status TEXT NOT NULL,
  promptDigest TEXT,
  errorMessage TEXT,
  createdAt INTEGER NOT NULL,
  completedAt INTEGER
)
''';

const String createAiOutputsTable = '''
CREATE TABLE ai_outputs (
  id TEXT PRIMARY KEY,
  aiJobId TEXT NOT NULL,
  outputType TEXT NOT NULL,
  content TEXT NOT NULL,
  createdAt INTEGER NOT NULL,
  FOREIGN KEY (aiJobId) REFERENCES ai_jobs(id) ON DELETE CASCADE
)
''';

const String createContactMilestonesTable = '''
CREATE TABLE contact_milestones (
  id TEXT PRIMARY KEY,
  contactId TEXT NOT NULL,
  type TEXT NOT NULL,
  label TEXT,
  milestoneDate INTEGER NOT NULL,
  isLunar INTEGER NOT NULL DEFAULT 0,
  isRecurring INTEGER NOT NULL DEFAULT 1,
  reminderEnabled INTEGER NOT NULL DEFAULT 0,
  reminderDaysBefore INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,
  FOREIGN KEY (contactId) REFERENCES contacts(id) ON DELETE CASCADE
)
''';

const String createAppPreferencesTable = '''
CREATE TABLE app_preferences (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updatedAt INTEGER NOT NULL
)
''';

const String createTodoGroupsTable = '''
CREATE TABLE todo_groups (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    sortOrder INTEGER NOT NULL DEFAULT 0,
    archivedAt INTEGER,
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER
)
''';

const String createTodoItemsTable = '''
CREATE TABLE todo_items (
    id TEXT PRIMARY KEY,
    groupId TEXT NOT NULL,
    parentItemId TEXT,
    title TEXT NOT NULL,
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    dueAt INTEGER,
    completedAt INTEGER,
    sourceType TEXT,
    sourceId TEXT,
    sortOrder INTEGER NOT NULL DEFAULT 0,
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,
    FOREIGN KEY (groupId) REFERENCES todo_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (parentItemId) REFERENCES todo_items(id) ON DELETE CASCADE
)
''';

const String createTodoItemContactsTable = '''
CREATE TABLE todo_item_contacts (
    id TEXT PRIMARY KEY,
    itemId TEXT NOT NULL,
    contactId TEXT NOT NULL,
    addedAt INTEGER NOT NULL,
    FOREIGN KEY (itemId) REFERENCES todo_items(id) ON DELETE CASCADE,
    FOREIGN KEY (contactId) REFERENCES contacts(id) ON DELETE CASCADE,
    UNIQUE(itemId, contactId)
)
''';

const String createTodoItemEventsTable = '''
CREATE TABLE todo_item_events (
    id TEXT PRIMARY KEY,
    itemId TEXT NOT NULL,
    eventId TEXT NOT NULL,
    addedAt INTEGER NOT NULL,
    FOREIGN KEY (itemId) REFERENCES todo_items(id) ON DELETE CASCADE,
    FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE,
    UNIQUE(itemId, eventId)
)
''';

// ──────────────────── 索引 ────────────────────

const String createContactsNameIndex =
    'CREATE INDEX idx_contacts_name ON contacts(name)';

const String createContactsPhoneIndex =
    'CREATE INDEX idx_contacts_phone ON contacts(phone)';

const String createContactsEmailIndex =
    'CREATE INDEX idx_contacts_email ON contacts(email)';

const String createContactsCreatedAtIndex =
    'CREATE INDEX idx_contacts_createdAt ON contacts(createdAt)';

const String createTagsNameIndex =
    'CREATE INDEX idx_tags_name ON tags(name)';

const String createContactTagsContactIdIndex =
    'CREATE INDEX idx_contact_tags_contactId ON contact_tags(contactId)';

const String createContactTagsTagIdIndex =
    'CREATE INDEX idx_contact_tags_tagId ON contact_tags(tagId)';

const String createEventTypesNameIndex =
    'CREATE INDEX idx_event_types_name ON event_types(name)';

const String createEventsEventTypeIdIndex =
    'CREATE INDEX idx_events_eventTypeId ON events(eventTypeId)';

const String createEventsStatusIndex =
    'CREATE INDEX idx_events_status ON events(status)';

const String createEventsStartAtIndex =
    'CREATE INDEX idx_events_startAt ON events(startAt)';

const String createEventsCreatedByContactIdIndex =
    'CREATE INDEX idx_events_createdByContactId ON events(createdByContactId)';

const String createEventParticipantsEventIdIndex =
    'CREATE INDEX idx_event_participants_eventId ON event_participants(eventId)';

const String createEventParticipantsContactIdIndex =
    'CREATE INDEX idx_event_participants_contactId ON event_participants(contactId)';

const String createEventSummariesEventIdIndex =
    'CREATE INDEX idx_event_summaries_eventId ON event_summaries(eventId)';

const String createEventSummariesSourceIndex =
    'CREATE INDEX idx_event_summaries_source ON event_summaries(source)';

const String createEventSummariesCreatedAtIndex =
    'CREATE INDEX idx_event_summaries_createdAt ON event_summaries(createdAt)';

const String createDailySummariesDateIndex =
    'CREATE INDEX idx_daily_summaries_summaryDate ON daily_summaries(summaryDate)';

const String createDailySummariesSourceIndex =
    'CREATE INDEX idx_daily_summaries_source ON daily_summaries(source)';

const String createDailySummariesCreatedAtIndex =
    'CREATE INDEX idx_daily_summaries_createdAt ON daily_summaries(createdAt)';

const String createAttachmentsFileNameIndex =
    'CREATE INDEX idx_attachments_fileName ON attachments(fileName)';

const String createAttachmentsMimeTypeIndex =
    'CREATE INDEX idx_attachments_mimeType ON attachments(mimeType)';

const String createAttachmentsChecksumIndex =
    'CREATE INDEX idx_attachments_checksum ON attachments(checksum)';

const String createAttachmentsStorageModeIndex =
    'CREATE INDEX idx_attachments_storageMode ON attachments(storageMode)';

const String createAttachmentsPreviewStatusIndex =
    'CREATE INDEX idx_attachments_previewStatus ON attachments(previewStatus)';

const String createAttachmentsSourceStatusIndex =
    'CREATE INDEX idx_attachments_sourceStatus ON attachments(sourceStatus)';

const String createAttachmentLinksAttachmentIdIndex =
    'CREATE INDEX idx_attachment_links_attachmentId ON attachment_links(attachmentId)';

const String createAttachmentLinksOwnerIndex =
    'CREATE INDEX idx_attachment_links_owner ON attachment_links(ownerType, ownerId)';

const String createAiJobsTargetIndex =
    'CREATE INDEX idx_ai_jobs_target ON ai_jobs(targetType, targetId)';

const String createAiJobsStatusIndex =
    'CREATE INDEX idx_ai_jobs_status ON ai_jobs(status)';

const String createAiOutputsAiJobIdIndex =
    'CREATE INDEX idx_ai_outputs_aiJobId ON ai_outputs(aiJobId)';

const String createContactMilestonesContactIdIndex =
    'CREATE INDEX idx_contact_milestones_contactId ON contact_milestones(contactId)';

const String createContactMilestonesTypeIndex =
    'CREATE INDEX idx_contact_milestones_type ON contact_milestones(type)';

const String createContactMilestonesMilestoneDateIndex =
    'CREATE INDEX idx_contact_milestones_milestoneDate ON contact_milestones(milestoneDate)';

const String createTodoGroupsSortOrderIndex =
    'CREATE INDEX idx_todo_groups_sortOrder ON todo_groups(sortOrder)';

const String createTodoItemsGroupIdIndex =
    'CREATE INDEX idx_todo_items_groupId ON todo_items(groupId)';

const String createTodoItemsParentItemIdIndex =
    'CREATE INDEX idx_todo_items_parentItemId ON todo_items(parentItemId)';

const String createTodoItemsStatusIndex =
    'CREATE INDEX idx_todo_items_status ON todo_items(status)';

const String createTodoItemContactsItemIdIndex =
    'CREATE INDEX idx_todo_item_contacts_itemId ON todo_item_contacts(itemId)';

const String createTodoItemContactsContactIdIndex =
    'CREATE INDEX idx_todo_item_contacts_contactId ON todo_item_contacts(contactId)';

const String createTodoItemEventsItemIdIndex =
    'CREATE INDEX idx_todo_item_events_itemId ON todo_item_events(itemId)';

const String createTodoItemEventsEventIdIndex =
    'CREATE INDEX idx_todo_item_events_eventId ON todo_item_events(eventId)';

// ──────────────────── quick_notes (v10) ────────────────────

const String createQuickNotesTable = '''
  CREATE TABLE IF NOT EXISTS quick_notes (
    id TEXT PRIMARY KEY,
    content TEXT NOT NULL,
    noteType TEXT NOT NULL DEFAULT 'knowledge',
    linkedContactId TEXT,
    linkedEventId TEXT,
    sessionGroup TEXT,
    aiMetadata TEXT,
    enrichedAt TEXT,
    captureDate TEXT NOT NULL,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    deletedAt TEXT
  )
''';

const String createQuickNotesCaptureDateIndex =
    'CREATE INDEX idx_quick_notes_captureDate ON quick_notes(captureDate)';

const String createQuickNotesSessionGroupIndex =
    'CREATE INDEX idx_quick_notes_sessionGroup ON quick_notes(sessionGroup)';

const String createQuickNotesLinkedContactIdIndex =
    'CREATE INDEX idx_quick_notes_linkedContactId ON quick_notes(linkedContactId)';

// ──────────────────── 语句列表 ────────────────────

/// 全量建表 + 索引（onCreate 使用）。
const List<String> createSchemaStatements = [
  createContactsTable,
  createTagsTable,
  createContactTagsTable,
  createEventTypesTable,
  createEventsTable,
  createEventParticipantsTable,
  createDailySummariesTable,
  createAttachmentsTable,
  createAttachmentLinksTable,
  createAiJobsTable,
  createAiOutputsTable,
  createContactMilestonesTable,
    createAppPreferencesTable,
    createTodoGroupsTable,
    createTodoItemsTable,
    createTodoItemContactsTable,
    createTodoItemEventsTable,
  createContactsNameIndex,
  createContactsPhoneIndex,
  createContactsEmailIndex,
  createContactsCreatedAtIndex,
  createTagsNameIndex,
  createContactTagsContactIdIndex,
  createContactTagsTagIdIndex,
  createEventTypesNameIndex,
  createEventsEventTypeIdIndex,
  createEventsStatusIndex,
  createEventsStartAtIndex,
  createEventsCreatedByContactIdIndex,
  createEventParticipantsEventIdIndex,
  createEventParticipantsContactIdIndex,
  createDailySummariesDateIndex,
  createDailySummariesSourceIndex,
  createDailySummariesCreatedAtIndex,
  createAttachmentsFileNameIndex,
  createAttachmentsMimeTypeIndex,
  createAttachmentsChecksumIndex,
  createAttachmentsStorageModeIndex,
  createAttachmentsPreviewStatusIndex,
  createAttachmentsSourceStatusIndex,
  createAttachmentLinksAttachmentIdIndex,
  createAttachmentLinksOwnerIndex,
  createAiJobsTargetIndex,
  createAiJobsStatusIndex,
  createAiOutputsAiJobIdIndex,
  createContactMilestonesContactIdIndex,
  createContactMilestonesTypeIndex,
  createContactMilestonesMilestoneDateIndex,
    createTodoGroupsSortOrderIndex,
    createTodoItemsGroupIdIndex,
    createTodoItemsParentItemIdIndex,
    createTodoItemsStatusIndex,
    createTodoItemContactsItemIdIndex,
    createTodoItemContactsContactIdIndex,
    createTodoItemEventsItemIdIndex,
    createTodoItemEventsEventIdIndex,
    createQuickNotesTable,
    createQuickNotesCaptureDateIndex,
    createQuickNotesSessionGroupIndex,
    createQuickNotesLinkedContactIdIndex,
];

/// v1 → v2 迁移语句（新增事件/附件/AI 表）。
const List<String> migrationToVersion2Statements = [
  createEventsTable,
  createEventParticipantsTable,
  createEventSummariesTable,
  createAttachmentsTable,
  createAttachmentLinksTable,
  createAiJobsTable,
  createAiOutputsTable,
  createEventsEventTypeIdIndex,
  createEventsStatusIndex,
  createEventsStartAtIndex,
  createEventsCreatedByContactIdIndex,
  createEventParticipantsEventIdIndex,
  createEventParticipantsContactIdIndex,
  createEventSummariesEventIdIndex,
  createEventSummariesSourceIndex,
  createEventSummariesCreatedAtIndex,
  createAttachmentsFileNameIndex,
  createAttachmentsMimeTypeIndex,
  createAttachmentsChecksumIndex,
  createAttachmentsStorageModeIndex,
  createAttachmentsPreviewStatusIndex,
  createAttachmentsSourceStatusIndex,
  createAttachmentLinksAttachmentIdIndex,
  createAttachmentLinksOwnerIndex,
  createAiJobsTargetIndex,
  createAiJobsStatusIndex,
  createAiOutputsAiJobIdIndex,
];
