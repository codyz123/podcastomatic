CREATE TABLE "clips_v2" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"name" varchar(255) NOT NULL,
	"start_time" real NOT NULL,
	"end_time" real NOT NULL,
	"transcript" text,
	"words" jsonb NOT NULL,
	"clippability_score" jsonb,
	"is_manual" boolean DEFAULT false,
	"tracks" jsonb,
	"caption_style" jsonb,
	"format" varchar(10),
	"generated_assets" jsonb,
	"hook_analysis" jsonb,
	"created_by_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "media_assets_v2" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid,
	"type" varchar(50) NOT NULL,
	"name" varchar(500) NOT NULL,
	"blob_url" text NOT NULL,
	"content_type" varchar(255),
	"size_bytes" bigint,
	"duration_seconds" real,
	"width" integer,
	"height" integer,
	"metadata" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "oauth_tokens_v2" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"podcast_id" uuid NOT NULL,
	"platform" varchar(50) NOT NULL,
	"access_token" text NOT NULL,
	"refresh_token" text NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"account_name" varchar(255) NOT NULL,
	"account_id" varchar(255),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "podcast_invitations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"podcast_id" uuid NOT NULL,
	"email" varchar(255) NOT NULL,
	"invited_by_id" uuid NOT NULL,
	"token" varchar(64) NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE TABLE "podcast_members" (
	"podcast_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"role" varchar(50) DEFAULT 'member' NOT NULL,
	"invited_by_id" uuid,
	"joined_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "podcast_members_podcast_id_user_id_pk" PRIMARY KEY("podcast_id","user_id")
);
--> statement-breakpoint
CREATE TABLE "podcasts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(255) NOT NULL,
	"description" text,
	"created_by_id" uuid NOT NULL,
	"cover_image_url" text,
	"podcast_metadata" jsonb,
	"brand_colors" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "projects_v2" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"podcast_id" uuid NOT NULL,
	"name" varchar(255) NOT NULL,
	"description" text,
	"audio_blob_url" text,
	"audio_file_name" varchar(255),
	"audio_fingerprint" varchar(64),
	"audio_duration" real DEFAULT 0,
	"episode_number" real,
	"season_number" real,
	"publish_date" timestamp with time zone,
	"show_notes" text,
	"explicit" boolean DEFAULT false,
	"guests" jsonb,
	"created_by_id" uuid,
	"stage_status" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "rendered_clips_v2" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"clip_id" uuid NOT NULL,
	"format" varchar(50) NOT NULL,
	"blob_url" text NOT NULL,
	"size_bytes" bigint,
	"rendered_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"refresh_token_hash" varchar(255) NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"user_agent" text,
	"ip_address" varchar(45)
);
--> statement-breakpoint
CREATE TABLE "text_snippets" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"index" integer NOT NULL,
	"name" varchar(500) NOT NULL,
	"content" text NOT NULL,
	"prompt" text,
	"focus_clip_id" uuid,
	"is_manual" boolean DEFAULT false NOT NULL,
	"created_by_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "transcripts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"audio_fingerprint" varchar(64),
	"text" text NOT NULL,
	"words" jsonb NOT NULL,
	"language" varchar(10) DEFAULT 'en',
	"name" varchar(255),
	"created_by_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "upload_sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"podcast_id" uuid NOT NULL,
	"episode_id" uuid NOT NULL,
	"upload_id" varchar(255) NOT NULL,
	"blob_key" varchar(255) NOT NULL,
	"pathname" varchar(500) NOT NULL,
	"filename" varchar(255) NOT NULL,
	"content_type" varchar(100) NOT NULL,
	"total_bytes" bigint NOT NULL,
	"chunk_size" integer NOT NULL,
	"total_parts" integer NOT NULL,
	"completed_parts" jsonb DEFAULT '[]'::jsonb,
	"uploaded_bytes" bigint DEFAULT 0,
	"status" varchar(20) DEFAULT 'pending' NOT NULL,
	"error_message" text,
	"blob_url" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"created_by_id" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" varchar(255) NOT NULL,
	"password_hash" varchar(255) NOT NULL,
	"name" varchar(255) NOT NULL,
	"avatar_url" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
ALTER TABLE "clips_v2" ADD CONSTRAINT "clips_v2_project_id_projects_v2_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects_v2"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "clips_v2" ADD CONSTRAINT "clips_v2_created_by_id_users_id_fk" FOREIGN KEY ("created_by_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "media_assets_v2" ADD CONSTRAINT "media_assets_v2_project_id_projects_v2_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects_v2"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "oauth_tokens_v2" ADD CONSTRAINT "oauth_tokens_v2_podcast_id_podcasts_id_fk" FOREIGN KEY ("podcast_id") REFERENCES "public"."podcasts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "podcast_invitations" ADD CONSTRAINT "podcast_invitations_podcast_id_podcasts_id_fk" FOREIGN KEY ("podcast_id") REFERENCES "public"."podcasts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "podcast_invitations" ADD CONSTRAINT "podcast_invitations_invited_by_id_users_id_fk" FOREIGN KEY ("invited_by_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "podcast_members" ADD CONSTRAINT "podcast_members_podcast_id_podcasts_id_fk" FOREIGN KEY ("podcast_id") REFERENCES "public"."podcasts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "podcast_members" ADD CONSTRAINT "podcast_members_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "podcast_members" ADD CONSTRAINT "podcast_members_invited_by_id_users_id_fk" FOREIGN KEY ("invited_by_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "podcasts" ADD CONSTRAINT "podcasts_created_by_id_users_id_fk" FOREIGN KEY ("created_by_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "projects_v2" ADD CONSTRAINT "projects_v2_podcast_id_podcasts_id_fk" FOREIGN KEY ("podcast_id") REFERENCES "public"."podcasts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "projects_v2" ADD CONSTRAINT "projects_v2_created_by_id_users_id_fk" FOREIGN KEY ("created_by_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rendered_clips_v2" ADD CONSTRAINT "rendered_clips_v2_clip_id_clips_v2_id_fk" FOREIGN KEY ("clip_id") REFERENCES "public"."clips_v2"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "text_snippets" ADD CONSTRAINT "text_snippets_project_id_projects_v2_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects_v2"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "text_snippets" ADD CONSTRAINT "text_snippets_focus_clip_id_clips_v2_id_fk" FOREIGN KEY ("focus_clip_id") REFERENCES "public"."clips_v2"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "text_snippets" ADD CONSTRAINT "text_snippets_created_by_id_users_id_fk" FOREIGN KEY ("created_by_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transcripts" ADD CONSTRAINT "transcripts_project_id_projects_v2_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects_v2"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transcripts" ADD CONSTRAINT "transcripts_created_by_id_users_id_fk" FOREIGN KEY ("created_by_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "upload_sessions" ADD CONSTRAINT "upload_sessions_podcast_id_podcasts_id_fk" FOREIGN KEY ("podcast_id") REFERENCES "public"."podcasts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "upload_sessions" ADD CONSTRAINT "upload_sessions_episode_id_projects_v2_id_fk" FOREIGN KEY ("episode_id") REFERENCES "public"."projects_v2"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "upload_sessions" ADD CONSTRAINT "upload_sessions_created_by_id_users_id_fk" FOREIGN KEY ("created_by_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "clips_v2_project_id_idx" ON "clips_v2" USING btree ("project_id");--> statement-breakpoint
CREATE INDEX "media_assets_v2_project_id_idx" ON "media_assets_v2" USING btree ("project_id");--> statement-breakpoint
CREATE INDEX "oauth_tokens_v2_podcast_id_idx" ON "oauth_tokens_v2" USING btree ("podcast_id");--> statement-breakpoint
CREATE INDEX "oauth_tokens_v2_platform_podcast_idx" ON "oauth_tokens_v2" USING btree ("platform","podcast_id");--> statement-breakpoint
CREATE INDEX "podcast_invitations_email_idx" ON "podcast_invitations" USING btree ("email");--> statement-breakpoint
CREATE INDEX "podcast_invitations_token_idx" ON "podcast_invitations" USING btree ("token");--> statement-breakpoint
CREATE INDEX "podcast_members_user_id_idx" ON "podcast_members" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "projects_v2_podcast_id_idx" ON "projects_v2" USING btree ("podcast_id");--> statement-breakpoint
CREATE INDEX "rendered_clips_v2_clip_id_idx" ON "rendered_clips_v2" USING btree ("clip_id");--> statement-breakpoint
CREATE INDEX "sessions_user_id_idx" ON "sessions" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "sessions_expires_at_idx" ON "sessions" USING btree ("expires_at");--> statement-breakpoint
CREATE INDEX "text_snippets_project_id_idx" ON "text_snippets" USING btree ("project_id");--> statement-breakpoint
CREATE INDEX "text_snippets_focus_clip_id_idx" ON "text_snippets" USING btree ("focus_clip_id");--> statement-breakpoint
CREATE INDEX "transcripts_project_id_idx" ON "transcripts" USING btree ("project_id");--> statement-breakpoint
CREATE INDEX "upload_sessions_episode_id_idx" ON "upload_sessions" USING btree ("episode_id");--> statement-breakpoint
CREATE INDEX "upload_sessions_status_idx" ON "upload_sessions" USING btree ("status");--> statement-breakpoint
CREATE INDEX "upload_sessions_expires_at_idx" ON "upload_sessions" USING btree ("expires_at");--> statement-breakpoint
CREATE INDEX "users_email_idx" ON "users" USING btree ("email");