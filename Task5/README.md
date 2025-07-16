# Задание 5 — Сетевые политики в Kubernetes

## Цель
Ограничить сетевой трафик между сервисами внутри кластера с помощью `NetworkPolicy`, разрешив только два «UI ↔ API» коннекта:
- `front-end` ↔ `back-end-api`
- `admin-front-end` ↔ `admin-back-end-api`

## Сервисы
Запущены четыре Pod'а с соответствующими Service и метками:
- `front-end-app` (role=front-end)  
- `back-end-api-app` (role=back-end-api)  
- `admin-front-end-app` (role=admin-front-end)  
- `admin-back-end-api-app` (role=admin-back-end-api)  

## Файл политики
В файле `non-admin-api-allow.yaml` описаны два NetworkPolicy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ui-to-backend
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: back-end-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: front-end
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: front-end
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-admin-ui-to-admin-backend
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: admin-back-end-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: admin-front-end
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: admin-front-end
```

**Применение:**
```bash
kubectl apply -f non-admin-api-allow.yaml
```

## Результаты тестирования

### 1. Внешний тест (пакет alpine, без меток)
```bash
kubectl run test-client \
  --rm -i -t \
  --image=alpine \
  --namespace=default \
  -- sh
```

```bash
# внутри тестовой сессии
/ # wget -qO- --timeout=2 http://front-end-app
# ✅ возвращает страницу nginx

/ # wget -qO- --timeout=2 http://admin-front-end-app
# ✅ возвращает страницу nginx

/ # wget -qO- --timeout=2 http://back-end-api-app
# ❌ таймаут (заблокировано)

/ # wget -qO- --timeout=2 http://admin-back-end-api-app
# ❌ таймаут (заблокировано)
```

### 2. Внутренний тест (debug-pods с нужными метками)

#### 2.1 debug-frontend (role=front-end)
```bash
kubectl run debug-frontend \
  --rm -i -t \
  --image=busybox:1.28 \
  --labels="role=front-end" \
  --namespace=default \
  -- sh
```

```bash
/ # wget -qO- --timeout=2 http://back-end-api-app
# ✅ возвращает страницу nginx

/ # wget -qO- --timeout=2 http://admin-back-end-api-app
# ❌ таймаут (заблокировано)
```

#### 2.2 debug-admin-frontend (role=admin-front-end)
```bash
kubectl run debug-admin-frontend \
  --rm -i -t \
  --image=busybox:1.28 \
  --labels="role=admin-front-end" \
  --namespace=default \
  -- sh
```

```bash
/ # wget -qO- --timeout=2 http://admin-back-end-api-app
# ✅ возвращает страницу nginx

/ # wget -qO- --timeout=2 http://back-end-api-app
# ❌ таймаут (заблокировано)
```

## Итог
Допускаются только трафик между:
- `front-end` ↔ `back-end-api`
- `admin-front-end` ↔ `admin-back-end-api`

Блокируются все остальные соединения (внешние pod'ы без меток, кросс-доступ между стеками и т.д.).