// New Relic is preloaded via `node -r newrelic` in start.sh (the proven way) — not imported here.
import { NestFactory } from '@nestjs/core';
import { Logger } from 'nestjs-pino';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.useLogger(app.get(Logger)); // pino — structured logs NR forwards when enabled
  await app.listen(process.env.PORT ?? 3000);
}
void bootstrap();
