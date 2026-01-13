
'use client';

import { useMemo, useState, useEffect } from 'react';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { differenceInDays, parseISO } from 'date-fns';
import { es } from 'date-fns/locale';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { Eye, Loader2, Users } from 'lucide-react';
import StudentProfileDialog from '@/components/student-profile-dialog';
import type { StudentWithDetails } from '@/lib/types';
import { useUser, useFirestore, useCollection, useMemoFirebase } from '@/firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';


export default function StudentsPage() {
  const [selectedStudent, setSelectedStudent] = useState<StudentWithDetails | null>(null);
  const [processedStudents, setProcessedStudents] = useState<StudentWithDetails[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // TODO: This logic needs to be revisited once booking functionality is implemented.
  // For now, it will result in an empty list, which is the desired state after removing demo data.
  useEffect(() => {
    // This is a placeholder for the logic that will fetch real student data
    // based on bookings. Since there's no booking system yet, we'll just
    // show an empty state.
    setProcessedStudents([]);
    setIsLoading(false);
  }, []);

  if (isLoading) {
    return (
      <div className="flex h-full w-full items-center justify-center p-16">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-8">
      <h1 className="font-headline text-3xl font-semibold">Mis Estudiantes</h1>

      <Card>
        <CardHeader>
          <CardTitle>Gestión de Estudiantes</CardTitle>
          <CardDescription>
            Aquí puedes ver y administrar a todos tus estudiantes en un solo lugar.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Nombre</TableHead>
                <TableHead>Estado</TableHead>
                <TableHead className="text-center">Clases Totales</TableHead>
                <TableHead>Última Asistencia</TableHead>
                <TableHead className="text-right">Acciones</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {processedStudents.length > 0 ? (
                processedStudents.map((student) => (
                  <TableRow key={student.studentId}>
                    <TableCell className="font-medium">
                      <div className="flex items-center gap-3">
                        <Avatar>
                          <AvatarImage src={`https://picsum.photos/seed/${student.studentId}/100/100`} />
                          <AvatarFallback>{student.name.charAt(0)}</AvatarFallback>
                        </Avatar>
                        {student.name}
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge
                        variant={
                          student.status === 'Activo' ? 'default' :
                            student.status === 'Inactivo' ? 'destructive' : 'secondary'
                        }
                        className={cn(student.status === 'Activo' && 'bg-green-600/80')}
                      >
                        {student.status}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-center">{student.totalBookings}</TableCell>
                    <TableCell className="text-muted-foreground">{student.lastAttendance}</TableCell>
                    <TableCell className="text-right">
                      <Button variant="ghost" size="icon" onClick={() => setSelectedStudent(student)}>
                        <Eye className="h-4 w-4" />
                        <span className="sr-only">Ver detalles</span>
                      </Button>
                    </TableCell>
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={5} className="h-48 text-center">
                    <div className="flex flex-col items-center gap-2">
                      <Users className="h-10 w-10 text-muted-foreground" />
                      <h3 className="font-semibold">Aún no tienes estudiantes</h3>
                      <p className="text-muted-foreground text-sm">Los estudiantes que agenden tus clases aparecerán aquí.</p>
                    </div>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Recupera Alumnos Inactivos</CardTitle>
          <CardDescription>
            Contacta a alumnos que no han vuelto a agendar clases recientemente.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Alumno</TableHead>
                <TableHead>Estado</TableHead>
                <TableHead>Última Clase</TableHead>
                <TableHead className="text-right">Acciones</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {/* Placeholder logic for inactive students - currently empty as per dashboard source */}
              <TableRow>
                <TableCell colSpan={4} className="h-24 text-center">
                  No hay alumnos inactivos por contactar en este momento.
                </TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </CardContent>
      </Card>
      {selectedStudent && (
        <StudentProfileDialog
          student={selectedStudent}
          open={!!selectedStudent}
          onOpenChange={(isOpen) => !isOpen && setSelectedStudent(null)}
        />
      )}
    </div>
  );
}
