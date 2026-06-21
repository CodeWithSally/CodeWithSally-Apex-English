import { useState } from "react";

export default function LikeButton({labelStr}: {labelStr: string}) {

  const [liked, setLiked] = useState(false);


  return (
    <button
      onClick={() => setLiked(likedValue => !likedValue)}
      className="border rounded-xl px-8 py-6 hover:bg-gray-50 transition"
    >
      <p className="text-5xl mb-1">{liked ? '❤️' : '🤍'}</p>
      <p className="text-gray-500">{labelStr}</p>
    </button>
  );
};