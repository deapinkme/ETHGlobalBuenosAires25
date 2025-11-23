import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Natural Gas Disruption Hook",
  description: "Uniswap V4 Hook for price convergence via asymmetric fees",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
