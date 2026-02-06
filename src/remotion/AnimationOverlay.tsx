import React from "react";
import { Img } from "remotion";
import { Lottie } from "@remotion/lottie";
import type { TrackClipData } from "./types";

interface AnimationOverlayProps {
  clip: TrackClipData;
}

export const AnimationOverlay: React.FC<AnimationOverlayProps> = ({ clip }) => {
  const { assetUrl, assetSource, lottieData, positionX, positionY } = clip;

  if (!assetUrl && !lottieData) return null;

  const containerStyle: React.CSSProperties = {
    position: "absolute",
    left: `${positionX ?? 50}%`,
    top: `${positionY ?? 50}%`,
    transform: "translate(-50%, -50%)",
    width: 200,
    height: 200,
    pointerEvents: "none",
  };

  if ((assetSource === "giphy" || assetSource === "tenor") && assetUrl) {
    return (
      <div style={containerStyle}>
        <Img src={assetUrl} style={{ width: "100%", height: "100%", objectFit: "contain" }} />
      </div>
    );
  }

  if (lottieData) {
    return (
      <div style={containerStyle}>
        <Lottie
          animationData={lottieData}
          loop={true}
          playbackRate={1}
          renderer="svg"
          style={{ width: "100%", height: "100%" }}
        />
      </div>
    );
  }

  return null;
};
