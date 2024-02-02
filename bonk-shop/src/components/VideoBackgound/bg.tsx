import React from 'react';

const VideoBackground = () => {
    return (
        <video autoPlay loop muted playsInline className="fixed right-0 bottom-0 min-w-full min-h-full w-auto h-auto -z-10 bg-cover object-cover">
            <source src={"/bgvid.mp4"} type="video/mp4" />
            Your browser does not support the video tag.
        </video>
    );
};

export default VideoBackground