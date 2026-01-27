import React, { useState, useCallback, useRef, useEffect } from "react";
import { UploadIcon, Cross2Icon, PlayIcon, PauseIcon, FileIcon } from "@radix-ui/react-icons";
import { Button, Card, CardContent, CardHeader, CardTitle, Progress } from "../ui";
import { useProjectStore } from "../../stores/projectStore";
import { useSettingsStore } from "../../stores/settingsStore";
import { formatDuration } from "../../lib/formats";
import WaveSurfer from "wavesurfer.js";

// Google Drive Picker configuration
const GOOGLE_CLIENT_ID = ""; // User will set this in settings
const GOOGLE_API_KEY = ""; // User will set this in settings
const GOOGLE_SCOPES = "https://www.googleapis.com/auth/drive.readonly";

interface AudioImportProps {
  onComplete: () => void;
}

export const AudioImport: React.FC<AudioImportProps> = ({ onComplete }) => {
  const { currentProject, updateProject } = useProjectStore();
  const { settings } = useSettingsStore();
  const [isDragging, setIsDragging] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [loadingMessage, setLoadingMessage] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [googlePickerLoaded, setGooglePickerLoaded] = useState(false);
  
  const waveformRef = useRef<HTMLDivElement>(null);
  const wavesurferRef = useRef<WaveSurfer | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const hasAudio = !!currentProject?.audioPath;

  // Load Google Picker API
  useEffect(() => {
    const loadGoogleApis = async () => {
      if (typeof window !== "undefined" && !window.gapi) {
        const script = document.createElement("script");
        script.src = "https://apis.google.com/js/api.js";
        script.onload = () => {
          window.gapi.load("picker", () => {
            setGooglePickerLoaded(true);
          });
        };
        document.body.appendChild(script);
      } else if (window.gapi) {
        window.gapi.load("picker", () => {
          setGooglePickerLoaded(true);
        });
      }
    };
    loadGoogleApis();
  }, []);

  // Initialize WaveSurfer
  useEffect(() => {
    if (waveformRef.current && hasAudio && currentProject?.audioPath) {
      wavesurferRef.current = WaveSurfer.create({
        container: waveformRef.current,
        waveColor: "hsl(262, 83%, 58%)",
        progressColor: "hsl(262, 83%, 40%)",
        cursorColor: "hsl(0, 0%, 95%)",
        barWidth: 2,
        barGap: 1,
        barRadius: 2,
        height: 100,
        normalize: true,
      });

      // In Tauri, we need to use the asset protocol for local files
      // For now, we'll use a blob URL approach
      wavesurferRef.current.on("ready", () => {
        const duration = wavesurferRef.current?.getDuration() || 0;
        if (duration && duration !== currentProject.audioDuration) {
          updateProject({ audioDuration: duration });
        }
      });

      wavesurferRef.current.on("play", () => setIsPlaying(true));
      wavesurferRef.current.on("pause", () => setIsPlaying(false));
      wavesurferRef.current.on("finish", () => setIsPlaying(false));

      return () => {
        wavesurferRef.current?.destroy();
      };
    }
  }, [hasAudio, currentProject?.audioPath]);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  }, []);

  const handleDrop = useCallback(
    async (e: React.DragEvent) => {
      e.preventDefault();
      setIsDragging(false);
      setError(null);

      const files = Array.from(e.dataTransfer.files);
      const audioFile = files.find((file) =>
        file.type.startsWith("audio/") ||
        /\.(mp3|wav|m4a|flac|ogg|aac)$/i.test(file.name)
      );

      if (!audioFile) {
        setError("Please drop an audio file (MP3, WAV, M4A, FLAC, OGG)");
        return;
      }

      await processAudioFile(audioFile);
    },
    []
  );

  const handleFileSelect = useCallback(
    async (e: React.ChangeEvent<HTMLInputElement>) => {
      setError(null);
      const file = e.target.files?.[0];
      if (file) {
        await processAudioFile(file);
      }
    },
    []
  );

  const openFilePicker = () => {
    fileInputRef.current?.click();
  };

  // Google Drive picker
  const openGoogleDrivePicker = useCallback(async () => {
    const clientId = (settings as any).googleClientId || GOOGLE_CLIENT_ID;
    const apiKey = (settings as any).googleApiKey || GOOGLE_API_KEY;

    if (!clientId || !apiKey) {
      setError("Google Drive integration requires API credentials. Add them in Settings.");
      return;
    }

    if (!googlePickerLoaded || !window.gapi) {
      setError("Google Picker is still loading. Please try again.");
      return;
    }

    try {
      // Get OAuth token
      const tokenClient = window.google?.accounts?.oauth2?.initTokenClient({
        client_id: clientId,
        scope: GOOGLE_SCOPES,
        callback: async (response: any) => {
          if (response.access_token) {
            createPicker(response.access_token, apiKey);
          }
        },
      });

      if (tokenClient) {
        tokenClient.requestAccessToken();
      } else {
        // Fallback: use gapi auth
        window.gapi.auth2?.getAuthInstance()?.signIn().then(() => {
          const token = window.gapi.auth2?.getAuthInstance()?.currentUser?.get()?.getAuthResponse()?.access_token;
          if (token) {
            createPicker(token, apiKey);
          }
        });
      }
    } catch (err) {
      console.error("Google Drive auth error:", err);
      setError("Failed to connect to Google Drive. Check your API credentials.");
    }
  }, [googlePickerLoaded, settings]);

  const createPicker = (accessToken: string, apiKey: string) => {
    if (!window.google?.picker) {
      setError("Google Picker not loaded. Please refresh and try again.");
      return;
    }
    
    const picker = new window.google.picker.PickerBuilder()
      .addView(
        new window.google.picker.DocsView()
          .setIncludeFolders(true)
          .setMimeTypes("audio/mpeg,audio/wav,audio/mp4,audio/x-m4a,audio/flac,audio/ogg")
      )
      .setOAuthToken(accessToken)
      .setDeveloperKey(apiKey)
      .setCallback(handleGoogleDriveSelection)
      .setTitle("Select Audio File from Google Drive")
      .build();
    picker.setVisible(true);
  };

  const handleGoogleDriveSelection = async (data: any) => {
    if (data.action === "picked" && data.docs?.[0]) {
      const file = data.docs[0];
      setIsLoading(true);
      setLoadingMessage("Downloading from Google Drive...");
      setError(null);

      try {
        // Download the file using Google Drive API
        const response = await fetch(
          `https://www.googleapis.com/drive/v3/files/${file.id}?alt=media`,
          {
            headers: {
              Authorization: `Bearer ${window.gapi.auth2?.getAuthInstance()?.currentUser?.get()?.getAuthResponse()?.access_token}`,
            },
          }
        );

        if (!response.ok) {
          throw new Error("Failed to download file from Google Drive");
        }

        const blob = await response.blob();
        const audioFile = new File([blob], file.name, { type: file.mimeType });
        await processAudioFile(audioFile);
      } catch (err) {
        console.error("Google Drive download error:", err);
        setError("Failed to download file from Google Drive");
      } finally {
        setIsLoading(false);
        setLoadingMessage("");
      }
    }
  };

  const processAudioFile = async (file: File) => {
    setIsLoading(true);
    setLoadingMessage("Processing audio...");
    setError(null);

    try {
      // For now, we'll store the file path (in a real Tauri app, we'd use the file system API)
      // Create a blob URL for preview
      const blobUrl = URL.createObjectURL(file);
      
      updateProject({
        audioPath: blobUrl,
        name: currentProject?.name || file.name.replace(/\.[^/.]+$/, ""),
      });

      // Load into WaveSurfer
      if (wavesurferRef.current) {
        await wavesurferRef.current.load(blobUrl);
      } else if (waveformRef.current) {
        // Create new instance if not exists
        wavesurferRef.current = WaveSurfer.create({
          container: waveformRef.current,
          waveColor: "hsl(262, 83%, 58%)",
          progressColor: "hsl(262, 83%, 40%)",
          cursorColor: "hsl(0, 0%, 95%)",
          barWidth: 2,
          barGap: 1,
          barRadius: 2,
          height: 100,
          normalize: true,
        });

        wavesurferRef.current.on("ready", () => {
          const duration = wavesurferRef.current?.getDuration() || 0;
          updateProject({ audioDuration: duration });
        });

        wavesurferRef.current.on("play", () => setIsPlaying(true));
        wavesurferRef.current.on("pause", () => setIsPlaying(false));

        await wavesurferRef.current.load(blobUrl);
      }
    } catch (err) {
      setError("Failed to process audio file");
      console.error(err);
    } finally {
      setIsLoading(false);
      setLoadingMessage("");
    }
  };

  const togglePlayback = () => {
    wavesurferRef.current?.playPause();
  };

  const clearAudio = () => {
    if (wavesurferRef.current) {
      wavesurferRef.current.destroy();
      wavesurferRef.current = null;
    }
    updateProject({ audioPath: "", audioDuration: 0 });
  };

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <div className="mb-8">
        <h2 className="text-2xl font-bold text-[hsl(var(--foreground))]">
          Import Audio
        </h2>
        <p className="text-[hsl(var(--muted-foreground))] mt-1">
          Upload your podcast episode audio file
        </p>
      </div>

      {/* Hidden file input */}
      <input
        ref={fileInputRef}
        type="file"
        accept="audio/*,.mp3,.wav,.m4a,.flac,.ogg,.aac"
        onChange={handleFileSelect}
        className="hidden"
      />

      {/* Drop Zone */}
      <Card className="mb-6">
        <CardContent>
          <div
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
            className={`
              border-2 border-dashed rounded-lg p-8 text-center transition-colors
              ${isDragging
                ? "border-[hsl(var(--primary))] bg-[hsl(var(--primary))]/10"
                : "border-[hsl(var(--border))]"
              }
            `}
          >
            <UploadIcon className="w-12 h-12 mx-auto mb-4 text-[hsl(var(--muted-foreground))]" />
            <p className="text-lg font-medium text-[hsl(var(--foreground))] mb-2">
              {isDragging ? "Drop your audio file here" : "Drag & drop audio file"}
            </p>
            <p className="text-sm text-[hsl(var(--muted-foreground))] mb-6">
              MP3, WAV, M4A, FLAC, OGG supported
            </p>

            {/* Import buttons */}
            <div className="flex flex-col sm:flex-row gap-3 justify-center">
              <Button onClick={openFilePicker} variant="primary" size="lg">
                <FileIcon className="w-4 h-4 mr-2" />
                Browse Files
              </Button>
              <Button onClick={openGoogleDrivePicker} variant="secondary" size="lg">
                <svg className="w-4 h-4 mr-2" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M4.433 22.396l4.83-8.387H22l-4.833 8.387H4.433zm7.192-9.471L6.79 4.167h6.795l4.833 8.758h-6.793zm6.795-8.758L22 4.167l-4.833 8.387-3.58-6.387 4.833-2z" />
                </svg>
                Google Drive
              </Button>
            </div>
          </div>

          {isLoading && (
            <div className="mt-4">
              <Progress value={50} className="mb-2" />
              <p className="text-sm text-[hsl(var(--muted-foreground))] text-center">
                {loadingMessage || "Processing audio..."}
              </p>
            </div>
          )}

          {error && (
            <p className="mt-4 text-sm text-[hsl(var(--destructive))] text-center">
              {error}
            </p>
          )}
        </CardContent>
      </Card>

      {/* Audio Preview */}
      {hasAudio && (
        <Card className="mb-6">
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>Audio Preview</CardTitle>
              <Button variant="ghost" size="sm" onClick={clearAudio}>
                <Cross2Icon className="w-4 h-4 mr-1" />
                Remove
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            {/* Waveform */}
            <div ref={waveformRef} className="mb-4" />

            {/* Playback Controls */}
            <div className="flex items-center justify-between">
              <Button variant="secondary" size="sm" onClick={togglePlayback}>
                {isPlaying ? (
                  <>
                    <PauseIcon className="w-4 h-4 mr-2" />
                    Pause
                  </>
                ) : (
                  <>
                    <PlayIcon className="w-4 h-4 mr-2" />
                    Play
                  </>
                )}
              </Button>
              <span className="text-sm text-[hsl(var(--muted-foreground))]">
                Duration: {formatDuration(currentProject?.audioDuration || 0)}
              </span>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Continue Button */}
      <div className="flex justify-end">
        <Button onClick={onComplete} disabled={!hasAudio}>
          Continue to Transcription
        </Button>
      </div>
    </div>
  );
};
