import { Module } from '@nestjs/common';
import { LoggerModule } from 'nestjs-pino';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [
    // pino structured logging. NR forwards these to New Relic Logs when the
    // agent is on; locally they go to stdout. LOG_LEVEL defaults to debug.
    LoggerModule.forRoot({
      pinoHttp: { level: process.env.LOG_LEVEL ?? 'debug' },
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
