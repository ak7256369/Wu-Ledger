#!/bin/bash
set -e

echo ">>> [1/2] Installing Frontend Dependencies..."
cd frontend
npm install

echo ">>> [2/2] Starting Dashboard on Port 3000..."
npm run dev
