import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  output: "standalone", // compiled, self-contained server for the prod Dockerfile
  outputFileTracingRoot: path.join(__dirname, "../../"), // monorepo: trace deps from repo root
};

export default nextConfig;
