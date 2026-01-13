
'use client';

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  CardFooter,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { CheckCircle, Rocket, XCircle } from 'lucide-react';
import PlanCalculator from '@/components/plan-calculator';
import { classPerformanceData } from '@/lib/class-data';

const features = {
  Comisión: [
    { text: 'Publicación de clases ilimitadas', included: true },
    { text: 'Gestión de agendamientos', included: true },
    { text: 'Perfil de instructor público', included: true },
    { text: 'Reportes básicos de rendimiento', included: true },
    { text: 'Comunicación por campañas de email', included: false },
    { text: 'Soporte prioritario', included: false },
    { text: 'Asistente IA para marketing', included: false },
    { text: 'Creación de academia', included: false },
  ],
  Básico: [
    { text: 'Publicación de clases ilimitadas', included: true },
    { text: 'Gestión de agendamientos', included: true },
    { text: 'Perfil de instructor público', included: true },
    { text: 'Reportes avanzados de rendimiento', included: true },
    { text: 'Comunicación por campañas de email', included: true },
    { text: 'Soporte prioritario', included: true },
    { text: 'Asistente IA para marketing', included: false },
    { text: 'Creación de academia', included: false },
  ],
  Pro: [
    { text: 'Publicación de clases ilimitadas', included: true },
    { text: 'Gestión de agendamientos', included: true },
    { text: 'Perfil de instructor público', included: true },
    { text: 'Reportes avanzados de rendimiento', included: true },
    { text: 'Comunicación por campañas de email', included: true },
    { text: 'Soporte prioritario', included: true },
    { text: 'Asistente IA para marketing', included: true },
    { text: 'Creación de academia (hasta 10 instr.)', included: true },
  ],
};

const plans = [
    {
        name: 'Comisión',
        price: '10%',
        period: 'por transacción',
        description: 'Ideal para empezar sin costos fijos. Solo pagas cuando generas ingresos.',
        cta: 'Mantener Plan Comisión',
        current: true,
    },
    {
        name: 'Básico',
        price: '$14.990',
        period: 'mensual + 5% comisión',
        description: 'Reduce la comisión y accede a más herramientas para crecer.',
        cta: 'Mejorar a Básico',
        current: false,
    },
    {
        name: 'Pro',
        price: '$29.990',
        period: 'mensual + 2.9% comisión',
        description: 'La comisión más baja y todas nuestras herramientas de IA para potenciar tu negocio.',
        cta: 'Mejorar a Pro',
        current: false,
    }
]

export default function ProPlanPage() {
  return (
    <div className="flex flex-col gap-8">
      <div className="text-center">
        <h1 className="font-headline text-4xl font-bold">
          Elige el Plan Perfecto para Ti
        </h1>
        <p className="mt-4 text-lg text-muted-foreground">
          Escala tu negocio con nuestras herramientas. Cambia de plan cuando quieras.
        </p>
      </div>

       <div className="grid grid-cols-1 gap-8 md:grid-cols-3">
        {plans.map((plan) => (
          <Card key={plan.name} className={`flex flex-col ${plan.name === 'Pro' ? 'border-primary ring-2 ring-primary' : ''}`}>
            <CardHeader className="space-y-2">
              <CardTitle className="font-headline text-2xl font-bold text-brand-purple">{plan.name}</CardTitle>
              <div>
                <p className="text-3xl font-bold">
                    {plan.price}
                </p>
                <p className="text-sm font-medium text-green-600">{plan.period}</p>
              </div>
              <CardDescription>{plan.description}</CardDescription>
            </CardHeader>
            <CardContent className="flex-grow space-y-4">
                <ul className="space-y-3">
                    {features[plan.name as keyof typeof features].map((feature) => (
                        <li key={feature.text} className="flex items-start gap-3">
                            {feature.included ? (
                                <CheckCircle className="h-5 w-5 text-green-500 mt-0.5 shrink-0" />
                            ) : (
                                <XCircle className="h-5 w-5 text-muted-foreground mt-0.5 shrink-0" />
                            )}
                            <span className={!feature.included ? 'text-muted-foreground' : ''}>
                                {feature.text}
                            </span>
                        </li>
                    ))}
                </ul>
            </CardContent>
            <CardFooter>
                 <Button className="w-full" variant={plan.current ? 'outline' : 'default'} disabled={plan.current}>
                    {plan.cta}
                </Button>
            </CardFooter>
          </Card>
        ))}
      </div>
      
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Rocket className="h-6 w-6" />
            Calculadora de Ganancias
          </CardTitle>
          <CardDescription>
            Simula tus ingresos mensuales y descubre qué plan te conviene más. Ajusta los valores para ver cómo cambian tus ganancias netas.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <PlanCalculator classPerformanceData={classPerformanceData} />
        </CardContent>
      </Card>

    </div>
  );
}
