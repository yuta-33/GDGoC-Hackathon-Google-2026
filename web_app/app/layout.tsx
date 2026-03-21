import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "PetFit Web",
  description: "Web demo frontend for the PetFit AI hackathon project."
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
