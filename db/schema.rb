# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_27_160001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "companies", force: :cascade do |t|
    t.bigint "prompt_id"
    t.string "name", null: false
    t.string "domain", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state", default: "pending", null: false
    t.index ["domain"], name: "index_companies_on_domain", unique: true
    t.index ["prompt_id"], name: "index_companies_on_prompt_id"
    t.index ["state"], name: "index_companies_on_state"
  end

  create_table "company_summaries", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.text "summary"
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "day"
    t.index ["company_id", "day"], name: "index_company_summaries_on_company_id_and_day", unique: true
    t.index ["company_id"], name: "index_company_summaries_on_company_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "company_id"
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state", default: "pending", null: false
    t.string "display_name"
    t.index ["company_id"], name: "index_contacts_on_company_id"
    t.index ["email"], name: "index_contacts_on_email", unique: true
    t.index ["state"], name: "index_contacts_on_state"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "origin_contact_id"
    t.bigint "category_id"
    t.bigint "status_id"
    t.string "title"
    t.boolean "hidden", default: false, null: false
    t.boolean "internal", default: false, null: false
    t.datetime "first_email_at"
    t.datetime "last_email_at"
    t.text "summary"
    t.datetime "summary_generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_conversations_on_category_id"
    t.index ["company_id"], name: "index_conversations_on_company_id"
    t.index ["last_email_at"], name: "index_conversations_on_last_email_at"
    t.index ["origin_contact_id"], name: "index_conversations_on_origin_contact_id"
    t.index ["status_id"], name: "index_conversations_on_status_id"
  end

  create_table "email_participants", force: :cascade do |t|
    t.bigint "email_id", null: false
    t.string "role", null: false
    t.string "address", null: false
    t.string "name"
    t.bigint "employee_id"
    t.bigint "contact_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_email_participants_on_address"
    t.index ["contact_id"], name: "index_email_participants_on_contact_id"
    t.index ["email_id", "role"], name: "index_email_participants_on_email_id_and_role"
    t.index ["email_id"], name: "index_email_participants_on_email_id"
    t.index ["employee_id"], name: "index_email_participants_on_employee_id"
  end

  create_table "emails", force: :cascade do |t|
    t.string "message_id"
    t.string "subject"
    t.text "content"
    t.text "summary"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "conversation_id"
    t.string "in_reply_to"
    t.string "reference_ids", default: [], null: false, array: true
    t.integer "attachments_count", default: 0, null: false
    t.index ["conversation_id"], name: "index_emails_on_conversation_id"
    t.index ["in_reply_to"], name: "index_emails_on_in_reply_to"
    t.index ["message_id"], name: "index_emails_on_message_id", unique: true
    t.index ["reference_ids"], name: "index_emails_on_reference_ids", using: :gin
    t.index ["sent_at"], name: "index_emails_on_sent_at"
  end

  create_table "employees", force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.index ["email"], name: "index_employees_on_email", unique: true
  end

  create_table "prompts", force: :cascade do |t|
    t.string "name", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_default", default: false, null: false
  end

  create_table "settings", force: :cascade do |t|
    t.string "org_domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "org_name"
    t.string "theme_color", default: "#3A908F", null: false
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.string "description"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_failure"
    t.text "metadata"
    t.integer "total_jobs", default: 0, null: false
    t.integer "completed_jobs", default: 0, null: false
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "batch_id"
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "statuses", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "rank", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rank"], name: "index_statuses_on_rank"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "companies", "prompts"
  add_foreign_key "company_summaries", "companies"
  add_foreign_key "contacts", "companies"
  add_foreign_key "conversations", "categories"
  add_foreign_key "conversations", "companies"
  add_foreign_key "conversations", "contacts", column: "origin_contact_id"
  add_foreign_key "conversations", "statuses"
  add_foreign_key "email_participants", "contacts"
  add_foreign_key "email_participants", "emails"
  add_foreign_key "email_participants", "employees"
  add_foreign_key "emails", "conversations"
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
