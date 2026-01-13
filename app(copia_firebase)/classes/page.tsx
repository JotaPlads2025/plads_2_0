
'use client';

import { useState, useMemo, useEffect } from 'react';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import {
  PlusCircle,
  ChevronLeft,
  ChevronRight,
  List,
  Calendar,
  Briefcase,
  Dumbbell,
  BookOpenCheck,
  Users,
  Loader2,
} from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import Link from 'next/link';
import { add, format, eachDayOfInterval, startOfMonth, endOfMonth, startOfWeek, endOfWeek, getDay, parse, compareAsc } from 'date-fns';
import { es } from 'date-fns/locale';
import ClassCalendar from '@/components/class-calendar';
import type { Class, Venue } from '@/lib/types';
import { studentData } from '@/lib/student-data';
import { venues as initialVenues } from '@/lib/venues-data';
import AttendeesDialog from '@/components/attendees-dialog';
import { useFirestore, useCollection, useMemoFirebase, useUser } from '@/firebase';
import { collection, doc, updateDoc } from 'firebase/firestore';
import { Switch } from '@/components/ui/switch';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { useToast } from '@/hooks/use-toast';


const dayNameToIndex: { [key: string]: number } = {
  'Domingo': 0,
  'Lunes': 1,
  'Martes': 2,
  'Miércoles': 3,
  'Jueves': 4,
  'Viernes': 5,
  'Sábado': 6,
};

// Generate calendar events from recurring classes
const generateCalendarEvents = (classes: Class[], month: Date): Class[] => {
    if (!classes || !month) return [];
    const events: Class[] = [];
    const monthStart = startOfMonth(month);
    const monthEnd = endOfMonth(month);
    // Use startOfWeek and endOfWeek with Spanish locale
    const interval = eachDayOfInterval({ start: startOfWeek(monthStart, { locale: es }), end: endOfWeek(monthEnd, { locale: es }) });
  
    interval.forEach(day => {
      const dayOfWeek = getDay(day); // Sunday is 0, Monday is 1...
      
      classes.forEach(cls => {
        if (cls.status === 'Active' && cls.schedules) {
            cls.schedules.forEach(schedule => {
                if (dayNameToIndex[schedule.day as keyof typeof dayNameToIndex] === dayOfWeek) {
                    const startTime = parse(schedule.startTime, 'HH:mm', new Date());
                    const eventDate = new Date(day.getFullYear(), day.getMonth(), day.getDate(), startTime.getHours(), startTime.getMinutes());

                     events.push({
                        ...cls,
                        id: `${cls.id}-${format(day, 'yyyy-MM-dd')}`,
                        date: eventDate,
                        schedule: `${schedule.startTime} - ${schedule.endTime}`,
                    });
                }
            });
        }
      });
    });
    return events;
  };


export default function ClassesPage() {
  const [currentMonth, setCurrentMonth] = useState<Date | null>(null);
  const [view, setView] = useState('calendar'); // 'list' or 'calendar'
  const [selectedClass, setSelectedClass] = useState<Class | null>(null);
  const [isAttendeesDialogOpen, setIsAttendeesDialogOpen] = useState(false);
  
  const { user } = useUser();
  const firestore = useFirestore();
  const { toast } = useToast();

  useEffect(() => {
    // Set the date on the client to avoid hydration mismatch
    setCurrentMonth(new Date());
  }, []);

  const classesRef = useMemoFirebase(() => {
    if (!user || !firestore) return null;
    return collection(firestore, 'instructors', user.uid, 'classes');
  }, [user, firestore]);
  
  const { data: classes, isLoading: isLoadingClasses } = useCollection<Class>(classesRef);

  const calendarEvents = useMemo(() => {
    if (!currentMonth) return [];
    const events = generateCalendarEvents(classes || [], currentMonth);
    // Sort events chronologically for the list view
    return events.sort((a, b) => compareAsc(a.date!, b.date!));
  }, [classes, currentMonth]);

  const { regularClasses, coachingClasses, bootcampClasses } = useMemo(() => {
    const regular: Class[] = [];
    const coaching: Class[] = [];
    const bootcamp: Class[] = [];

    (classes || []).forEach(cls => {
        switch (cls.category) {
            case 'Coaching':
                coaching.push(cls);
                break;
            case 'Bootcamp':
                bootcamp.push(cls);
                break;
            default: // Dance, Sports, Health
                regular.push(cls);
                break;
        }
    });

    return { regularClasses: regular, coachingClasses: coaching, bootcampClasses: bootcamp };
  }, [classes]);


  const handleClassSelect = (cls: Class) => {
    setSelectedClass(cls);
    setIsAttendeesDialogOpen(true);
  };
  
  const handleAttendeesDialogClose = () => {
    setIsAttendeesDialogOpen(false);
    setSelectedClass(null);
  }

  const handleStatusChange = async (classId: string, newStatus: boolean) => {
    if (!firestore || !user) return;

    const status = newStatus ? 'Active' : 'Inactive';
    const classRef = doc(firestore, 'instructors', user.uid, 'classes', classId);

    try {
        await updateDoc(classRef, { status });
        toast({
            title: "¡Estado actualizado!",
            description: `La clase ha sido marcada como ${status.toLowerCase()}.`
        });
    } catch (error) {
        console.error("Error updating class status:", error);
        toast({
            variant: "destructive",
            title: "Error al actualizar",
            description: "No se pudo cambiar el estado de la clase."
        });
    }
  };

  const goToPreviousMonth = () => {
    if (!currentMonth) return;
    setCurrentMonth(add(currentMonth, { months: -1 }));
  };

  const goToNextMonth = () => {
    if (!currentMonth) return;
    setCurrentMonth(add(currentMonth, { months: 1 }));
  };
  
  const goToToday = () => {
    setCurrentMonth(new Date());
  };


 const renderClassTable = (classes: Class[]) => (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Clase</TableHead>
          <TableHead className="text-center">Cupos</TableHead>
          <TableHead className="text-right">Estado (Activo/Inactivo)</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {classes.length > 0 ? (
          classes.map((cls) => (
            <TableRow key={cls.id}>
              <TableCell className="font-medium">{cls.name}</TableCell>
              <TableCell className="text-center">{cls.availability}</TableCell>
              <TableCell className="text-right">
                <Switch
                  checked={cls.status === 'Active'}
                  onCheckedChange={(checked) => handleStatusChange(cls.id, checked)}
                />
              </TableCell>
            </TableRow>
          ))
        ) : (
          <TableRow>
            <TableCell colSpan={3} className="text-center h-24">
              No tienes clases en esta categoría.
            </TableCell>
          </TableRow>
        )}
      </TableBody>
    </Table>
  );

  const getVenueName = (venueId: string) => {
    return initialVenues.find(v => v.id === venueId)?.name || 'Sede no especificada';
  }


  return (
    <div className="flex flex-col gap-8">
      <div className="flex items-center justify-between">
        <h1 className="font-headline text-3xl font-semibold">Mis Clases</h1>
        <Link href="/classes/new">
          <Button>
            <PlusCircle className="mr-2 h-4 w-4" />
            Crear Nueva Clase
          </Button>
        </Link>
      </div>

      <Card>
        <CardHeader>
           <div className="flex items-center justify-between">
             <div className="flex items-center gap-4">
              <h2 className="text-xl font-semibold capitalize">
                {currentMonth ? format(currentMonth, 'MMMM yyyy', { locale: es }) : 'Cargando...'}
              </h2>
              <div className="flex items-center gap-2">
                <Button variant="outline" size="icon" onClick={goToPreviousMonth} disabled={!currentMonth}>
                  <ChevronLeft className="h-4 w-4" />
                </Button>
                 <Button variant="outline" size="sm" onClick={goToToday} disabled={!currentMonth}>
                  Hoy
                </Button>
                <Button variant="outline" size="icon" onClick={goToNextMonth} disabled={!currentMonth}>
                  <ChevronRight className="h-4 w-4" />
                </Button>
              </div>
            </div>
             <div className="hidden items-center gap-2 rounded-md bg-muted p-1 sm:flex">
                <Button variant={view === 'calendar' ? 'secondary' : 'ghost'} size="sm" onClick={() => setView('calendar')} className="gap-2">
                    <Calendar className="h-4 w-4" />
                    Calendario
                </Button>
                <Button variant={view === 'list' ? 'secondary' : 'ghost'} size="sm" onClick={() => setView('list')} className="gap-2">
                    <List className="h-4 w-4" />
                    Lista
                </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {isLoadingClasses ? (
            <div className="flex h-64 items-center justify-center">
              <Loader2 className="h-8 w-8 animate-spin" />
            </div>
          ) : view === 'calendar' ? (
              <ClassCalendar 
                classes={calendarEvents} 
                month={currentMonth} 
                venues={initialVenues}
                onClassSelect={handleClassSelect}
             />
          ) : (
             <Table>
                <TableHeader>
                    <TableRow>
                        <TableHead>Clase</TableHead>
                        <TableHead>Fecha y Hora</TableHead>
                        <TableHead>Sede</TableHead>
                        <TableHead className="text-right">Acciones</TableHead>
                    </TableRow>
                </TableHeader>
                <TableBody>
                    {calendarEvents.length > 0 ? (
                        calendarEvents.map(cls => (
                            <TableRow key={cls.id}>
                                <TableCell className="font-medium">{cls.name}</TableCell>
                                <TableCell>
                                    <span className='capitalize'>{cls.date ? format(cls.date, 'eeee dd, HH:mm', { locale: es }) : 'Fecha no disponible'}</span>
                                </TableCell>
                                <TableCell>{getVenueName(cls.venueId)}</TableCell>
                                <TableCell className="text-right">
                                    <Button variant="ghost" size="sm" onClick={() => handleClassSelect(cls)}>
                                        <Users className="h-4 w-4 mr-2" />
                                        Ver Asistentes
                                    </Button>
                                </TableCell>
                            </TableRow>
                        ))
                    ) : (
                        <TableRow>
                            <TableCell colSpan={4} className="text-center h-24">
                                No hay clases programadas para este mes.
                            </TableCell>
                        </TableRow>
                    )}
                </TableBody>
             </Table>
          )}
        </CardContent>
      </Card>
      
      <Card>
        <CardHeader>
          <CardTitle>Gestión de Clases</CardTitle>
          <CardDescription>
            Activa o desactiva tus clases, coachings y bootcamps desde aquí.
          </CardDescription>
        </CardHeader>
        <CardContent>
            {isLoadingClasses ? (
                 <div className="flex h-48 items-center justify-center">
                    <Loader2 className="h-8 w-8 animate-spin" />
                 </div>
            ) : (
                <Tabs defaultValue="regular">
                    <TabsList className="grid w-full grid-cols-3">
                    <TabsTrigger value="regular">
                        <BookOpenCheck className="mr-2 h-4 w-4" />
                        Clases Regulares
                    </TabsTrigger>
                    <TabsTrigger value="coaching">
                        <Dumbbell className="mr-2 h-4 w-4" />
                        Coaching
                    </TabsTrigger>
                    <TabsTrigger value="bootcamp">
                        <Briefcase className="mr-2 h-4 w-4" />
                        Bootcamps
                    </TabsTrigger>
                    </TabsList>
                    <TabsContent value="regular" className="mt-4">
                    {renderClassTable(regularClasses)}
                    </TabsContent>
                    <TabsContent value="coaching" className="mt-4">
                    {renderClassTable(coachingClasses)}
                    </TabsContent>
                    <TabsContent value="bootcamp" className="mt-4">
                    {renderClassTable(bootcampClasses)}
                    </TabsContent>
                </Tabs>
            )}
        </CardContent>
      </Card>


      {selectedClass && (
        <AttendeesDialog
          open={isAttendeesDialogOpen}
          onOpenChange={handleAttendeesDialogClose}
          classData={selectedClass}
          students={studentData}
          venues={initialVenues}
        />
      )}
    </div>
  );
}

    