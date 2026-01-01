FROM node:24-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS build
WORKDIR /app
COPY . /app

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

# Create complete fake .git structure for platforms that do shallow clones
RUN mkdir -p /prod/api/.git/logs /prod/api/.git/refs/heads && \
    echo "ref: refs/heads/main" > /prod/api/.git/HEAD && \
    echo "0000000000000000000000000000000000000000 646d99473d46e7dd455d1374cd14fb27de324fda cobalt <noreply@cobalt.tools> 1735714574 +0000	commit: cobalt-singapore" > /prod/api/.git/logs/HEAD && \
    echo "646d99473d46e7dd455d1374cd14fb27de324fda" > /prod/api/.git/refs/heads/main && \
    printf '[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n\tbare = false\n[remote "origin"]\n\turl = https://github.com/imputnet/cobalt\n\tfetch = +refs/heads/*:refs/remotes/origin/*\n[branch "main"]\n\tremote = origin\n\tmerge = refs/heads/main\n' > /prod/api/.git/config

FROM base AS api
WORKDIR /app

COPY --from=build --chown=node:node /prod/api /app

USER node

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
