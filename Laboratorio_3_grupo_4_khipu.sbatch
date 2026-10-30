#!/bin/bash
# =====================================================================
# Laboratorio_3_grupo_4 - Reidentificación de personas (CO-BYOL)
# Job de Slurm para KHIPU (UTEC). Ver la sección 0 del notebook.
#
# Uso (desde ~/lab3, con la carpeta logs/ ya creada):
#   Notebook completo (genera el notebook ejecutado para entregar):
#     sbatch Laboratorio_3_grupo_4_khipu.sbatch
#   Solo entrenar algunas corridas (nombres separados por ':'):
#     sbatch --export=ALL,LAB3_TO_RUN=R1_byol:R2_cobyol_ws0.2,LAB3_TRAIN_ONLY=1 Laboratorio_3_grupo_4_khipu.sbatch
#   Solo las corridas RF99-ResNet50 desde cero (R9/R10; costosas, se reanudan solas si se agota el tiempo):
#     sbatch --export=ALL,LAB3_TO_RUN=R9_byol_rf99,LAB3_TRAIN_ONLY=1 Laboratorio_3_grupo_4_khipu.sbatch
#   Omitir las corridas RF99 / reducir su costo:
#     sbatch --export=ALL,LAB3_RF=0 Laboratorio_3_grupo_4_khipu.sbatch
#     sbatch --export=ALL,LAB3_EPOCHS_RF=60,LAB3_BATCH_RF=32 Laboratorio_3_grupo_4_khipu.sbatch
#   Prueba rápida en debug-gpu:
#     sbatch -p debug-gpu -t 00:30:00 --gres=shard:4 --export=ALL,LAB3_SMOKE=1 Laboratorio_3_grupo_4_khipu.sbatch
# =====================================================================
#SBATCH --job-name=lab3_g4
#SBATCH --partition=gpu
#SBATCH --gres=shard:8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err

set -eo pipefail
NB=Laboratorio_3_grupo_4_Reidentificacion_de_personas
export LAB3_ROOT="${LAB3_ROOT:-$HOME/lab3}"
cd "$LAB3_ROOT"

source "$LAB3_ROOT/venv/bin/activate"
export LD_LIBRARY_PATH="/opt/ohpc/pub/libs/gnu12/python3/3.13.2/lib:${LD_LIBRARY_PATH:-}"
export PYTHONUNBUFFERED=TRUE

echo "Job ${SLURM_JOB_ID} en $(hostname) | inicio $(date)"
echo "LAB3_TO_RUN=${LAB3_TO_RUN:-todas} LAB3_TRAIN_ONLY=${LAB3_TRAIN_ONLY:-0} LAB3_SMOKE=${LAB3_SMOKE:-0} LAB3_BATCH=${LAB3_BATCH:-128}"
echo "LAB3_RF=${LAB3_RF:-1} LAB3_EPOCHS_RF=${LAB3_EPOCHS_RF:-100} LAB3_BATCH_RF=${LAB3_BATCH_RF:-64} LAB3_RF_FINAL=${LAB3_RF_FINAL:-1}"
nvidia-smi || true

if [ "${LAB3_TRAIN_ONLY:-0}" = "1" ]; then
    # Modo script: secciones 1-8, sin figuras interactivas
    export MPLBACKEND=Agg
    jupyter nbconvert --to python "${NB}.ipynb" --output "lab3_script_${SLURM_JOB_ID}"
    python "lab3_script_${SLURM_JOB_ID}.py"
    rm -f "lab3_script_${SLURM_JOB_ID}.py"
else
    # Modo notebook completo: guarda el notebook ejecutado con todas sus salidas
    OUT_SUBDIR=runs
    [ "${LAB3_SMOKE:-0}" = "1" ] && OUT_SUBDIR=runs_smoke
    mkdir -p "$OUT_SUBDIR"
    jupyter nbconvert --to notebook --execute "${NB}.ipynb" \
        --ExecutePreprocessor.timeout=-1 \
        --ExecutePreprocessor.kernel_name=python3 \
        --output-dir "$OUT_SUBDIR" --output "${NB}_ejecutado"
fi

echo "Fin $(date)"
