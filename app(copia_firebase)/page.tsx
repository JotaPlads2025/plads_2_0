'use client';

import { useState, useMemo } from 'react';
import { Download } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { DashboardCard, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/dashboard-card';
import { MultiSelectFilter, type Option } from '@/components/ui/multi-select-filter';
import { venues as initialVenues } from '@/lib/venues-data';
import { useUser, useFirestore, useCollection, useMemoFirebase } from '@/firebase';
import { collection } from 'firebase/firestore';
import type { Class } from '@/lib/types';
import AiAssistantForm from '@/components/ai-assistant-form';

// Modular Components
import { KpiStats } from '@/components/dashboard/kpi-stats';
import { RevenueChart } from '@/components/dashboard/revenue-chart';
import { ClassPerformanceTable } from '@/components/dashboard/class-performance';

const monthOptions: Option[] = [
  { value: 'all', label: 'Todos los Meses' },
  { value: 'Ene', label: 'Enero' }, { value: 'Feb', label: 'Febrero' },
  { value: 'Mar', label: 'Marzo' }, { value: 'Abr', label: 'Abril' },
  { value: 'May', label: 'Mayo' }, { value: 'Jun', label: 'Junio' },
  { value: 'Jul', label: 'Julio' }, { value: 'Ago', label: 'Agosto' },
  { value: 'Sep', label: 'Septiembre' }, { value: 'Oct', label: 'Octubre' },
  { value: 'Nov', label: 'Noviembre' }, { value: 'Dic', label: 'Diciembre' },
];

const dayOptions: Option[] = [
  { value: 'all', label: 'Todos los Días' },
  { value: 'Lun', label: 'Lunes' }, { value: 'Mar', label: 'Martes' },
  { value: 'Mie', label: 'Miércoles' }, { value: 'Jue', label: 'Jueves' },
  { value: 'Vie', label: 'Viernes' }, { value: 'Sab', label: 'Sábado' },
  { value: 'Dom', label: 'Domingo' },
];

const classTypeOptions: Option[] = [
  { value: 'all', label: 'Todas las Clases' },
  { value: 'Dance', label: 'Clases Regulares' },
  { value: 'Coaching', label: 'Coaching' },
  { value: 'Bootcamp', label: 'Bootcamps' },
];

const venueOptions: Option[] = [
  { value: 'all', label: 'Todas las Sedes' },
  ...initialVenues.map(v => ({ value: v.id, label: v.name })),
];

export default function Dashboard() {
  const [selectedMonths, setSelectedMonths] = useState<string[]>(['all']);
  const [selectedDays, setSelectedDays] = useState<string[]>(['all']);
  const [selectedClassTypes, setSelectedClassTypes] = useState<string[]>(['all']);
  const [selectedVenues, setSelectedVenues] = useState<string[]>(['all']);

  const { user } = useUser();
  const firestore = useFirestore();

  const classesRef = useMemoFirebase(() => {
    if (!user || !firestore) return null;
    return collection(firestore, 'instructors', user.uid, 'classes');
  }, [user, firestore]);

  const { data: classes, isLoading: isLoadingClasses } = useCollection<Class>(classesRef);

  const filteredData = useMemo(() => {
    if (!classes) return [];
    return classes;
  }, [classes, selectedMonths, selectedDays, selectedClassTypes, selectedVenues]);

  const aggregatedKpis = useMemo(() => {
    if (!classes) {
      return { revenue: 0, newStudents: 0, retention: 0, activeClasses: 0, coaching: 0, bootcamps: 0 };
    }

    const activeClasses = classes.filter(c => c.status === 'Active');
    const coaching = activeClasses.filter(c => c.category === 'Coaching').length;
    const bootcamps = activeClasses.filter(c => c.category === 'Bootcamp').length;

    return {
      revenue: classes.reduce((acc, cls) => acc + (cls.revenue || 0), 0),
      newStudents: 0,
      retention: 0,
      activeClasses: activeClasses.length,
      coaching: coaching,
      bootcamps: bootcamps,
    };
  }, [classes]);

  return (
    <div className="flex flex-col gap-8">
      <div>
        <h1 className="font-headline text-3xl font-semibold">
          ¡Hola de nuevo, {user?.displayName?.split(' ')[0] || 'Artista'}!
        </h1>
        <p className="text-muted-foreground mt-1">
          Qué bueno verte. Sigamos inspirando al mundo a través del movimiento.
        </p>
      </div>

      <div className="flex items-center justify-between space-y-2">
        <h2 className="text-2xl font-bold tracking-tight">Dashboard</h2>
      </div>

      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Resumen General</TabsTrigger>
          <TabsTrigger value="analytics">Análisis Detallado</TabsTrigger>
          <TabsTrigger value="ai_assistant">Asistente IA</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          {/* Filters Section */}
          <DashboardCard>
            <CardHeader>
              <div className='flex justify-between items-center'>
                <div>
                  <CardTitle>Filtros</CardTitle>
                  <CardDescription>
                    Selecciona uno o más filtros para visualizar tus datos.
                  </CardDescription>
                </div>
                <Button className="bg-primary hover:bg-primary/90 text-primary-foreground" disabled>
                  <Download className="mr-2 h-4 w-4" />
                  Descargar Excel
                </Button>
              </div>
            </CardHeader>
            <CardContent className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <MultiSelectFilter
                title="Mes"
                options={monthOptions}
                selectedValues={selectedMonths}
                onSelectionChange={setSelectedMonths}
              />
              <MultiSelectFilter
                title="Día de la semana"
                options={dayOptions}
                selectedValues={selectedDays}
                onSelectionChange={setSelectedDays}
              />
              <MultiSelectFilter
                title="Tipo de Clase"
                options={classTypeOptions}
                selectedValues={selectedClassTypes}
                onSelectionChange={setSelectedClassTypes}
              />
              <MultiSelectFilter
                title="Sede"
                options={venueOptions}
                selectedValues={selectedVenues}
                onSelectionChange={setSelectedVenues}
              />
            </CardContent>
          </DashboardCard>

          {/* KPI Stats */}
          <KpiStats data={aggregatedKpis} />

          {/* Main Content Grid */}
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-7">
            <div className="col-span-1 lg:col-span-4">
              <RevenueChart />
            </div>
            <div className="col-span-1 lg:col-span-3">
              <ClassPerformanceTable classes={filteredData} isLoading={isLoadingClasses} />
            </div>
          </div>
        </TabsContent>

        <TabsContent value="analytics" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
            <div className="col-span-1 lg:col-span-7">
              <ClassPerformanceTable classes={filteredData} isLoading={isLoadingClasses} />
            </div>
          </div>
        </TabsContent>

        <TabsContent value="ai_assistant" className="space-y-4">
          <DashboardCard accentColor="purple">
            <CardHeader>
              <CardTitle>Asistente de IA</CardTitle>
              <CardDescription>
                Haz preguntas en lenguaje natural sobre tus datos de rendimiento.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <AiAssistantForm />
            </CardContent>
          </DashboardCard>
        </TabsContent>
      </Tabs>
    </div>
  );
}
