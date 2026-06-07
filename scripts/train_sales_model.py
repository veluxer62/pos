"""
매출 예측 TFLite 모델 학습 스크립트.

사용법:
    1. POS 앱의 SQLite DB에서 데이터를 CSV로 내보낸다.
       (DailySalesReport 테이블의 closedAt, netRevenue 컬럼)

    2. 의존성 설치:
       pip install numpy pandas scikit-learn tensorflow

    3. 스크립트 실행:
       python scripts/train_sales_model.py --input sales_data.csv

    4. 생성된 모델을 Flutter assets에 복사:
       cp model_output/sales_forecast.tflite assets/models/

    5. pubspec.yaml의 flutter.assets에 경로가 있는지 확인:
       assets:
         - assets/models/

    6. DI에서 서비스 교체 (lib/core/di/providers.dart):
       ISalesForecastService salesForecastService(Ref ref) =>
           TFLiteSalesForecastService()..loadModel();

CSV 형식:
    date,net_revenue
    2024-01-01,150000
    2024-01-02,200000
    ...

모델 입력 (3 features):
    - day_of_week_norm: (weekday - 1) / 6.0  (0.0 = 월, 1.0 = 일)
    - prev_revenue_norm: 전일 매출 / max_revenue
    - rolling_avg_norm: 7일 평균 / max_revenue

모델 출력 (1):
    - predicted_revenue_norm: 예측 매출 / max_revenue
"""

import argparse
import os

import numpy as np
import pandas as pd


def build_features(df: pd.DataFrame):
    df = df.copy()
    df["date"] = pd.to_datetime(df["date"])
    df = df.sort_values("date").reset_index(drop=True)

    max_revenue = df["net_revenue"].max()
    if max_revenue == 0:
        raise ValueError("매출 데이터가 모두 0입니다.")

    df["day_of_week_norm"] = (df["date"].dt.weekday) / 6.0
    df["prev_revenue_norm"] = df["net_revenue"].shift(1) / max_revenue
    df["rolling_avg_norm"] = (
        df["net_revenue"].rolling(7, min_periods=7).mean().shift(1) / max_revenue
    )
    df["target"] = df["net_revenue"] / max_revenue

    df = df.dropna()
    x = df[["day_of_week_norm", "prev_revenue_norm", "rolling_avg_norm"]].values
    y = df["target"].values
    return x, y, max_revenue


def train_and_export(csv_path: str, output_dir: str = "model_output"):
    import tensorflow as tf
    from sklearn.model_selection import train_test_split

    df = pd.read_csv(csv_path)
    required = {"date", "net_revenue"}
    if not required.issubset(df.columns):
        raise ValueError(f"CSV에 필요한 컬럼이 없습니다: {required - set(df.columns)}")

    x, y, max_revenue = build_features(df)
    print(f"학습 샘플: {len(x)}, max_revenue: {max_revenue:,.0f}")

    x_train, x_val, y_train, y_val = train_test_split(
        x, y, test_size=0.2, random_state=42
    )

    model = tf.keras.Sequential(
        [
            tf.keras.layers.Dense(
                16, activation="relu", input_shape=(3,), name="hidden1"
            ),
            tf.keras.layers.Dense(8, activation="relu", name="hidden2"),
            tf.keras.layers.Dense(1, name="output"),
        ]
    )
    model.compile(optimizer="adam", loss="mse", metrics=["mae"])

    model.fit(
        x_train,
        y_train,
        validation_data=(x_val, y_val),
        epochs=200,
        batch_size=16,
        verbose=1,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(
                monitor="val_loss", patience=20, restore_best_weights=True
            )
        ],
    )

    val_loss, val_mae = model.evaluate(x_val, y_val, verbose=0)
    print(f"\n검증 MAE (정규화): {val_mae:.4f}  →  실제 매출 오차: {val_mae * max_revenue:,.0f}원")

    os.makedirs(output_dir, exist_ok=True)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    output_path = os.path.join(output_dir, "sales_forecast.tflite")
    with open(output_path, "wb") as f:
        f.write(tflite_model)

    print(f"\n모델 저장: {output_path}  ({len(tflite_model) / 1024:.1f} KB)")
    print("다음 단계: cp model_output/sales_forecast.tflite assets/models/")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="매출 예측 TFLite 모델 학습")
    parser.add_argument("--input", required=True, help="입력 CSV 파일 경로")
    parser.add_argument("--output", default="model_output", help="출력 디렉토리")
    args = parser.parse_args()
    train_and_export(args.input, args.output)
