#!/bin/bash
set -euo pipefail

# Cleanup file sementara sebelumnya
rm -f both_added.txt both_modified.txt deleted_by_us.txt deleted_by_them.txt

echo "📦 Memulai penyelesaian konflik Git otomatis..."

# 1. Deteksi konflik berdasarkan status
git status --porcelain | grep '^AA ' | cut -c4- > both_added.txt || true
git status --porcelain | grep '^UU ' | cut -c4- > both_modified.txt || true

git status | grep 'deleted by us:' | sed 's/^[[:space:]]*deleted by us:[[:space:]]*//' > deleted_by_us.txt || true
git status | grep 'deleted by them:' | sed 's/^[[:space:]]*deleted by them:[[:space:]]*//' > deleted_by_them.txt || true

# Fungsi pengecualian path
is_excluded() {
    [[ "$1" == arch/arm64/configs/* ]]
}

# 2. Handle "both added" -> ambil versi theirs
if [[ -s both_added.txt ]]; then
    echo "🆕 Menangani 'both added' (mengambil versi theirs)..."
    while read -r file; do
        if is_excluded "$file"; then
            echo "  ⏭️ Skip (excluded): $file"
            continue
        fi
        echo "  [both added] $file"
        git checkout --theirs -- "$file"
        git add "$file"
    done < both_added.txt
fi

# 3. Handle "deleted by us" -> hapus
if [[ -s deleted_by_us.txt ]]; then
    echo "🗑️ Menghapus file (deleted by us)..."
    while read -r file; do
        if is_excluded "$file"; then
            echo "  ⏭️ Skip (excluded): $file"
            continue
        fi
        if [ -e "$file" ]; then
            echo "  [deleted by us] $file"
            git rm "$file"
        fi
    done < deleted_by_us.txt
fi

# 4. Handle "deleted by them" -> hapus
if [[ -s deleted_by_them.txt ]]; then
    echo "🗑️ Menghapus file (deleted by them)..."
    while read -r file; do
        if is_excluded "$file"; then
            echo "  ⏭️ Skip (excluded): $file"
            continue
        fi
        if [ -e "$file" ]; then
            echo "  [deleted by them] $file"
            git rm "$file"
        fi
    done < deleted_by_them.txt
fi

# 5. Tampilkan 'both modified' untuk resolusi manual
if [[ -s both_modified.txt ]]; then
    echo "⚠️ Perlu diselesaikan manual (both modified):"
    cat both_modified.txt
else
    echo "✅ Tidak ada konflik 'both modified'."
fi

# Cleanup file temporary setelah eksekusi
rm -f both_added.txt both_modified.txt deleted_by_us.txt deleted_by_them.txt

echo "🎉 Konflik 'added' & 'deleted' selesai ditangani otomatis."
