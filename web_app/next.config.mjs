/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "moncheri.jp"
      },
      {
        protocol: "https",
        hostname: "www.moncheri.jp"
      }
    ]
  }
};

export default nextConfig;
