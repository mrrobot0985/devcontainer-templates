#!/bin/bash
set -e

# Data Engineering with Spark — bootstrap script
# Installs Spark 3.5, Jupyter, and Python data libraries

SPARK_VERSION="3.5.1"
HADOOP_VERSION="3"

# Install Python packages
pip install --no-cache-dir \
  pyspark==${SPARK_VERSION} \
  jupyter \
  polars \
  pyarrow \
  pandas \
  numpy \
  scikit-learn \
  matplotlib \
  seaborn \
  minio \
  delta-spark

# Download and install Spark
SPARK_DIR="/opt/spark"
if [ ! -d "$SPARK_DIR" ]; then
    echo "Downloading Apache Spark ${SPARK_VERSION}..."
    curl -fsSL "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | tar -xz -C /tmp
    mv "/tmp/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" "$SPARK_DIR"
fi

# Set environment variables
cat > /etc/profile.d/spark.sh <<EOF
export SPARK_HOME=${SPARK_DIR}
export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin
export PYSPARK_PYTHON=/usr/local/bin/python
export PYSPARK_DRIVER_PYTHON=/usr/local/bin/python
EOF

# Create Jupyter config
mkdir -p /home/vscode/.jupyter
chown -R vscode:vscode /home/vscode/.jupyter

echo "Data Engineering environment ready."
echo "  Spark: ${SPARK_VERSION}"
echo "  Jupyter: http://localhost:8888"
echo "  Spark UI: http://localhost:8080"
